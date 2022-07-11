#!/usr/bin/env bash

REGION="$1"
NAME="$2"
RG_ID="$3"

if [[ -z "${IBMCLOUD_API_KEY}" ]]; then
  echo "IBMCLOUD_API_KEY must be provided as an environment variable" >&2
  exit 1
fi

if [[ -n "${BIN_DIR}" ]]; then
  export PATH="${BIN_DIR}:${PATH}"
fi

if ! command -v jq 1> /dev/null 2> /dev/null; then
  echo "jq cli not found" >&2
  exit 1
fi

IAM_TOKEN=$(curl -s -X POST "https://iam.cloud.ibm.com/identity/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=${IBMCLOUD_API_KEY}" | jq -r '.access_token')

VOLUME_DATA=$(jq -n -c --arg ZONE "${REGION}-1" --arg NAME "${NAME}" --arg RG_ID "${RG_ID}" \
  -c '{"name":$NAME,"iops":100,"capacity":50,"zone":{"name":$ZONE},"profile":{"name":"custom"},"resource_group":{"id":$RG_ID}}')

curl -X POST "https://${REGION}.iaas.cloud.ibm.com/v1/volumes?version=2022-07-05&generation=2" -H "Authorization: Bearer $IAM_TOKEN" -d "${VOLUME_DATA}"
