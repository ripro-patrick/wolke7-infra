#!/bin/bash
l() 
{
    echo "${1}"
    if [[ $2 -gt 0 ]]; then
        l "exiting with eror code ${2}"
        exit ${2}
    fi
}

function retry {
  local n=0
  local max=1000
  local delay=1
  local cmd="${@: 2}"
  # echo "waiting on ${1}"
  # echo "cmd: ${cmd}"
  while true; do
    $(eval $cmd) && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        if [[ $n%10 -eq 0 ]]; then
            l "Waiting on ${1} to be ready. Attempt $n/$max:"
        fi
        sleep $delay;
      else
        l "The command has failed after $n attempts. ($@)" 1
      fi
    }
  done
}

INGRESS=./ingress
TIMEOUT=10
REGION=LON1

# export INGRESS=./ingress/ TIMEOUT=10 REGION=LON1 CLUSTER=wolke7-infra
