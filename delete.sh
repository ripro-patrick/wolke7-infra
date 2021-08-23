#!/bin/bash
. base.sh

# switch context back to "infra"-cluster
civo k8s config wolke7-infra --region=${REGION} --save --merge --switch

# delete clusters
for i in $(civo k8s ls --region=${REGION} -o custom -f name | grep -v wolke7-infra); do
    kubectl config delete-context ${i} 2>/dev/null
    kubectl config delete-cluster ${i} 2>/dev/null
    kubectl config delete-user ${i} 2>/dev/null
    sed "s,CLUSTER,${i},g" cluster/cluster.yaml | kubectl delete -f -
done

# remove kubectl configs
l "remove kubectl configs"
kubectl config delete-context wolke7-infra 2>/dev/null
kubectl config delete-cluster wolke7-infra 2>/dev/null
kubectl config delete-user wolke7-infra 2>/dev/null

# remove cluster
l "remove cluster"
civo k8s rm wolke7-infra --yes --region=${REGION} 

