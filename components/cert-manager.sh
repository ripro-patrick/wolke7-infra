#!/bin/bash

# deploy traefik
l "--- deploy traefik"
civo k8s app add cert-manager --cluster=${CLUSTER} --region=${REGION}

civo k8s config ${CLUSTER} --region=${REGION} --save --merge --switch

certmanagerDeployed() { kubectl rollout status deployment -n cert-manager cert-manager >/dev/null 2>&1; return $?; }
retry "ert-manager" "certmanagerDeployed"
l "--- cert-manager is deployed"
