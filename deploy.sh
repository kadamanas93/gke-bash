#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m'

[ -z "${GOOGLE_CREDENTIALS}" ]  && echo >&2 "Need to set GOOGLE_CREDENTIALS"  && exit 1
[ -z "${GCP_PROJECT}" ]         && echo >&2 "Need to set GCP_PROJECT"         && exit 1
[ -z "${GCP_ZONE}" ]            && echo >&2 "Need to set GCP_ZONE"            && exit 1
[ -z "${GKE_NAME}" ]            && echo >&2 "Need to set GKE_NAME"            && exit 1
[ -z "${GKE_INSTANCES}" ]       && GKE_INSTANCES=2

CMDS="gcloud kubectl helm"
 
for i in $CMDS
do
	type -P "$i" &>/dev/null && continue  || { echo "$i command not found."; exit 1; }
done

printf "${GREEN}Creating GKE cluster...\n${NC}"
gcloud auth activate-service-account --key-file "${GOOGLE_CREDENTIALS}"
gcloud config set compute/zone "${GCP_ZONE}"

gcloud container clusters create "${GKE_NAME}" --num-nodes="${GKE_INSTANCES}"

printf "${GREEN}Setting up Helm...\n${NC}"
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller --wait

printf "${GREEN}Setting up Nginx ingress...\n${NC}"
helm install --name nginx-ingress stable/nginx-ingress --set rbac.create=true --set controller.publishService.enabled=true
