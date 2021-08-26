#!/bin/bash
. base.sh

CLUSTER=${1:-"wolke7-infra"}

# switch context back to "infra"-cluster
civo k8s config wolke7-infra --region=${REGION} --save --merge --switch

# delete clusters
for i in $(civo k8s ls --region=${REGION} -o custom -f name | grep -v wolke7-infra | grep wolke7); do
    kubectl config delete-context ${i} 2>/dev/null
    kubectl config delete-cluster ${i} 2>/dev/null
    kubectl config delete-user ${i} 2>/dev/null
    civo k8s remove ${i} --region=${REGION}
done

# remove kubectl configs
l "remove kubectl configs"
kubectl config delete-context wolke7-infra 2>/dev/null
kubectl config delete-cluster wolke7-infra 2>/dev/null
kubectl config delete-user wolke7-infra 2>/dev/null

# remove cluster
l "remove cluster"
civo k8s rm wolke7-infra --yes --region=${REGION} 

