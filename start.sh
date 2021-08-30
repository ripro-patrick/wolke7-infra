#!/bin/bash
. base.sh

CLUSTER=${1:-"wolke7-infra"}

# delete configs
l "configure kubectl"
kubectl config delete-context ${CLUSTER} 2>/dev/null
kubectl config delete-context ${CLUSTER} 2>/dev/null
kubectl config delete-user ${CLUSTER} 2>/dev/null

# create the cluster
l "---------------------------------------"
l "creating the cluster"
clusterAvailable() { civo k8s get ${CLUSTER} --region=${REGION} -o custom -f Status 2>/dev/null; return $?; }
if clusterAvailable; then
    l "--- cluster is already available..."
    civo k8s config ${CLUSTER} --region=${REGION} --save --merge --switch
else
    civo k8s create ${CLUSTER} --size=g3.k3s.medium --nodes=3 --region=${REGION} \
        --save --merge --switch --wait 
fi

sleep ${TIMEOUT}

DNS=$(civo k8s get ${CLUSTER} --region=${REGION} -o custom -f "DNSEntry")
l "DNS: ${DNS}"

kubectl create cm cluster-vars --from-literal=DNS=${DNS} --from-literal=REGION=${REGION} --from-literal=CLUSTER=${CLUSTER}

# required for rancher - disabled as rancher is not being installed
#. components/cert-manager.sh

. components/traefik.sh

# sleep ${TIMEOUT}
# # scale the cluster up
# l "--- scale up the cluster"
# civo k8s pool scale ${CLUSTER} $(civo k8s show ${CLUSTER} --region=${REGION} -o json | jq -r ".pools[0].id") -n 3 --region=${REGION}

sleep ${TIMEOUT}

. components/argocd.sh

sleep ${TIMEOUT}

argocd app create ${CLUSTER}-infra \
    --repo https://github.com/ripro-patrick/wolke7-infra.git --path infra-cluster \
    --dest-name ${CLUSTER} --dest-namespace default \
    --sync-policy=auto --self-heal --sync-option Prune=true --allow-empty \
    --upsert

verifyCRDProvider() { kubectl get ProviderConfig >/dev/null 2>&1; return $?; }
retry "CRD Provider available" "verifyCRDProvider"
l "--- CRD Provider is available"

curl -s https://raw.githubusercontent.com/crossplane-contrib/provider-civo/main/examples/civo/provider/provider.yaml | \
    sed "s,<replace with base64 encoded Civo API KEY>,$(civo apikey show -o custom -f key | base64),g" | \
    # sed "s,ProviderConfig,Configuration,g" | \
    # sed "s,civo.crossplane.io/v1alpha1,pkg.crossplane.io/v1,g" |
    kubectl apply -f - 

AWS_PROFILE=ripro && echo -e "[default]\naws_access_key_id = $(aws configure get aws_access_key_id --profile $AWS_PROFILE)\naws_secret_access_key = $(aws configure get aws_secret_access_key --profile $AWS_PROFILE)" > creds.conf
kubectl create secret generic aws-creds -n crossplane-system --from-file=creds=./creds.conf

# verifyCRDProvider() { kubectl get ProviderConfig >/dev/null 2>&1; return $?; }
# retry "CRD Provider available" "verifyCRDProvider"
# l "--- CRD Provider is available"
# kubectl apply -f https://raw.githubusercontent.com/crossplane/crossplane/release-1.3/docs/snippets/configure/aws/providerconfig.yaml


