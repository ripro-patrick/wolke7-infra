#!/bin/bash

# deploy traefik
l "--- deploy traefik"
civo k8s app add Traefik --cluster=${CLUSTER} --region=${REGION}

civo k8s config ${CLUSTER} --region=${REGION} --save --merge --switch

traefikDeployed() { kubectl rollout status deployment -n kube-system traefik >/dev/null 2>&1; return $?; }
retry "traefik" "traefikDeployed"
l "--- traefik is deployed"
