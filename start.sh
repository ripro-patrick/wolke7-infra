#!/bin/bash
. base.sh

CLUSTER=wolke7-infra

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
    civo k8s create ${CLUSTER} --size=g3.k3s.medium --nodes=1 --region=${REGION} \
        --save --merge --switch --wait 
fi

sleep ${TIMEOUT}

DNS=$(civo k8s get ${CLUSTER} --region=${REGION} -o custom -f "DNSEntry")
l "DNS: ${DNS}"

. components/traefik.sh

sleep ${TIMEOUT}
# scale the cluster up
l "--- scale up the cluster"
civo k8s pool scale ${CLUSTER} $(civo k8s show ${CLUSTER} --region=${REGION} -o json | jq -r ".pools[0].id") -n 2 --region=${REGION}

. components/argocd.sh


