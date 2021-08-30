#!/bin/bash

civo k8s config ${CLUSTER} --region=${REGION} --save --merge --switch

# deploy argocd
l "--- deploy argocd"
civo k8s app add argo-cd --cluster=${CLUSTER} --region=${REGION}

argoExists() { kubectl get deploy argocd-server -n argocd >/dev/null 2>&1; return $?; }
retry "argocd" "argoExists"
sleep 15
l "--- argocd-server deployment exists"

l "--- patch argocd ingress"
kubectl -n argocd patch deployment argocd-server --type json \
    -p='[ { "op": "replace", "path":"/spec/template/spec/containers/0/command","value": ["argocd-server","--staticassets","/shared/app","--insecure"] }]'
sed "s,CIVODNS,${DNS},g" ${INGRESS}/argocd-ingress.yaml | kubectl apply -f -

argoDeployed() { kubectl rollout status deployment -n argocd argocd-server >/dev/null 2>&1; return $?; }
retry "argocd" "argoDeployed"
l "--- argocd-server deployment deployed"
argoSecretsDeployed() { kubectl get secret -n argocd argocd-initial-admin-secret >/dev/null 2>&1; return $?; }
retry "argocd" "argoSecretsDeployed"
l "--- argocd secrets are deployed"

l "argocd.${DNS}" 
l "argo-password: $(kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode ; echo)"

ARGO_URL=argocd.${DNS}
ARGO_USER=admin
ARGO_PW=$(kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode ; echo)

argoStarted() { 
    argocd login ${ARGO_URL} --insecure --username=${ARGO_USER} --password=${ARGO_PW} >/dev/null 2>&1
    return $?
}

retry "argocd" "argoStarted"
l "--- argocd is started"

argocd cluster add ${CLUSTER}

# store ArgoCD access details in secre
# for portainer
kubectl create ns portainer
kubectl create secret generic -n portainer portainer-password \
  --from-literal=password="${ARGO_PW}"
# and for grafana
kubectl create ns prometheus
kubectl create secret generic -n prometheus grafana-password \
  --from-literal=password="${ARGO_PW}"
