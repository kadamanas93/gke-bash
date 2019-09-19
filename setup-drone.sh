#!/bin/bash

# Need to setup these creds:
# API_SERVER
# KUBERNETES_TOKEN
# GCR_CREDENTIALS

set -ex

add_or_update_drone() {
  SECRET_NAME=$1
  SECRET_VALUE=$2
  if drone secret ls --repository "${REPO}" | grep "${SECRET_NAME}"; then
    drone secret update --repository "${REPO}" \
      --name "${SECRET_NAME}" --data "${SECRET_VALUE}"
  else
    drone secret add --repository "${REPO}" \
      --name "${SECRET_NAME}" --data "${SECRET_VALUE}"
  fi

}

[ -z "${DRONE_SERVER}" ]        && echo >&2 "Need to set DRONE_SERVER"        && exit 1
[ -z "${DRONE_TOKEN}" ]         && echo >&2 "Need to set DRONE_TOKEN"         && exit 1
[ -z "${GOOGLE_CREDENTIALS}" ]  && echo >&2 "Need to set GOOGLE_CREDENTIALS"  && exit 1
[ -z "${GCP_PROJECT}" ]         && echo >&2 "Need to set GCP_PROJECT"         && exit 1
[ -z "${GCP_ZONE}" ]            && echo >&2 "Need to set GCP_ZONE"            && exit 1
[ -z "${GKE_NAME}" ]            && echo >&2 "Need to set GKE_NAME"            && exit 1
[ -z "${REPO}" ]                && echo >&2 "Need to set REPO"            && exit 1

if [ "$(uname -s)" == "Darwin*" ]; then
  alias sed=gsed
fi

CMDS="gcloud kubectl drone jq sed"
 
for i in $CMDS
do
	type -P "$i" &>/dev/null && continue  || { echo "$i command not found."; exit 1; }
done

# Add/Update GCR_CREDENTIALS
val=$(cat "$GOOGLE_CREDENTIALS")
add_or_update_drone gcr_credentials "${val}"

# Add/Update API_SERVER
API_SERVER=$(kubectl cluster-info | grep 'Kubernetes master' | awk -F' ' '{print $NF}' | sed 's/\x1b\[[^\x1b]*m//g')
API_SERVER='https://35.194.42.53'
add_or_update_drone api_server "${API_SERVER}"

# Add/update tiller token
TILLER_SECRET=$(kubectl -n kube-system get secrets | grep tiller | awk -F' ' '{print $1}')
KUBERNETES_TOKEN=$(kubectl -n kube-system get secret "${TILLER_SECRET}" -o json | jq -r .data.token | base64 --decode)
add_or_update_drone kubernetes_token "${KUBERNETES_TOKEN}"
