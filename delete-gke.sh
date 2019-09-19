#!/bin/bash

set -e
[ -z "${GOOGLE_CREDENTIALS}" ]  && echo >&2 "Need to set GOOGLE_CREDENTIALS"  && exit 1
[ -z "${GCP_PROJECT}" ]         && echo >&2 "Need to set GCP_PROJECT"         && exit 1
[ -z "${GCP_ZONE}" ]            && echo >&2 "Need to set GCP_ZONE"            && exit 1
[ -z "${GKE_NAME}" ]            && echo >&2 "Need to set GKE_NAME"            && exit 1

CMDS="gcloud"
 
for i in $CMDS
do
	type -P "$i" &>/dev/null && continue  || { echo "$i command not found."; exit 1; }
done

printf "${GREEN}Deleting GKE cluster...\n${NC}"
gcloud auth activate-service-account --key-file "${GOOGLE_CREDENTIALS}"
gcloud config set compute/zone "${GCP_ZONE}"
gcloud container clusters delete "${GKE_NAME}" --quiet
