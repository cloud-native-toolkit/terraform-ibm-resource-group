#!/usr/bin/env bash

RESOURCE_GROUP_NAME="$1"
PURGE="$2"

if [[ -z "${RESOURCE_GROUP_NAME}" ]] || [[ -z "${PURGE}" ]]; then
  echo "Usage: purge-volumes.sh {resource group name} {purge flag}" >&2
  exit 1
fi

if [[ -z "${IBMCLOUD_API_KEY}" ]] && [[ -z "${TF_VAR_ibmcloud_api_key}" ]]; then
  echo "IBMCLOUD_API_KEY or TF_VAR_ibmcloud_api_key must be provided as an environment variable" >&2
  exit 1
fi

if [[ -z "${IBMCLOUD_API_KEY}" ]]; then
  export TF_VAR_ibmcloud_api_key="${IBMCLOUD_API_KEY}"
fi

if [[ -n "${BIN_DIR}" ]]; then
  export PATH="${BIN_DIR}:${PATH}"
fi

if ! command -v jq 1> /dev/null 2> /dev/null; then
  echo "jq cli not found" >&2
  exit 1
fi

RED='\033[0;31m'
YELLOW='\033[0;33m'
WHITE='\033[0;37m'
NC='\033[0m'

IAM_TOKEN=$(curl -s -X POST "https://iam.cloud.ibm.com/identity/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=${IBMCLOUD_API_KEY}" | jq -r '.access_token')

ACCOUNT_ID=$(curl -s -X GET 'https://iam.cloud.ibm.com/v1/apikeys/details' \
  -H "Authorization: Bearer $IAM_TOKEN" -H "IAM-Apikey: ${IBMCLOUD_API_KEY}" \
  -H 'Content-Type: application/json' | jq -r '.account_id')

# check if resource group exists

RESULT=$(curl -s --url "https://resource-controller.cloud.ibm.com/v2/resource_groups?account_id=$ACCOUNT_ID&name=$RESOURCE_GROUP_NAME"  \
  --header "Authorization: Bearer $IAM_TOKEN" \
  --header 'Content-Type: application/json')

COUNT=$(echo "${RESULT}" | jq '.resources | length' -r)

if [[ "${COUNT}" -eq 0 ]]; then
  echo "Resource group not found: ${RESOURCE_GROUP_NAME}" >&2
  exit 0
fi

echo "Found resource group $RESOURCE_GROUP_NAME..."
RG_ID=$(echo "${RESULT}" | jq '.resources[].id' -r)
RG_CRN=$(echo "${RESULT}" | jq '.resources[].crn' -r)
echo "ID: $RG_ID"
echo "CRN: $RG_CRN"

#check to make sure the RG has the automation tag before checking volumes
TAGS=$(curl -s -X GET \
  --header "Authorization: Bearer $IAM_TOKEN" \
  --header 'Content-Type: application/json' \
  "https://tags.global-search-tagging.cloud.ibm.com/v3/tags?tag_type=user&providers=ghost&offset=0&limit=10&order_by_name=asc&attached_to=$RG_CRN")

if [[ "$TAGS" != *"$AUTOMATION_TAG"* ]]; then
  echo "Automation tag not found: ${AUTOMATION_TAG}"
  exit 0
fi

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR=".tmp/resource-group"
fi
mkdir -p "${TMP_DIR}"

echo "[]" > "${TMP_DIR}/${RESOURCE_GROUP_NAME}.volumes"

## get volumes in resource group
for region in au-syd in-che jp-osa jp-tok kr-seo eu-de eu-gb ca-tor us-south us-east br-sao; do
  echo "Finding volumes in region: $region"

  url="https://$region.iaas.cloud.ibm.com/v1/volumes?version=2022-07-05&generation=2&limit=100"
  while [[ -n "${url}" ]]; do
    echo "  Getting volumes: ${url}"

    result=$(curl -s -X GET \
      -H "Authorization: Bearer $IAM_TOKEN" \
      -H "Content-Type: application/json" \
      "${url}")

    matching_volumes=$(echo "${result}" | jq -c --arg ID "${RG_ID}" '[.volumes[] | select(.resource_group.id == $ID)]')

    if [[ -z "${matching_volumes}" ]]; then
      matching_volumes="[]"
    fi

    jq --argjson VOLUMES "${matching_volumes}" '[.] + [$VOLUMES] | add' "${TMP_DIR}/${RESOURCE_GROUP_NAME}.volumes" > "${TMP_DIR}/${RESOURCE_GROUP_NAME}.volumes.tmp"
    cp "${TMP_DIR}/${RESOURCE_GROUP_NAME}.volumes.tmp" "${TMP_DIR}/${RESOURCE_GROUP_NAME}.volumes" && rm "${TMP_DIR}/${RESOURCE_GROUP_NAME}.volumes.tmp"

    url=$(echo "${result}" | jq -r '.next.href // empty')
  done
done

## if volumes not found return with 0 rc
if [[ $(jq '. | length' "${TMP_DIR}/${RESOURCE_GROUP_NAME}.volumes") -eq 0 ]]; then
  echo "No volumes found in resource group"
  exit 0
fi

if [[ "${PURGE}" == "true" ]]; then
  echo "Purging volumes:"
  jq -c '.[] | {"id": .id, "zone": .zone.name}' "${TMP_DIR}/${RESOURCE_GROUP_NAME}.volumes"

  jq -c '.[] | {"id": .id, "zone": .zone.name}' "${TMP_DIR}/${RESOURCE_GROUP_NAME}.volumes" | while read -r volume; do
    volume_id=$(echo "${volume}" | jq -r '.id')
    zone=$(echo "${volume}" | jq -r '.zone')

    region=$(echo "${zone}" | sed -E "s/(.*)-[0-9]/\1/g")

    url="https://$region.iaas.cloud.ibm.com/v1/volumes/${volume_id}?version=2022-07-05&generation=2"

    echo "Deleting volume (${volume_id}, ${region}): ${url}"
    curl -X DELETE \
      -H "Authorization: Bearer $IAM_TOKEN" \
      -H "Content-Type: application/json" \
      "${url}"

    while [[ $(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $IAM_TOKEN" -H "Content-Type: application/json" "${url}") -ne 404 ]]; do
      echo "  Waiting for volume to be deleted: ${volume_id}"
      sleep 30
    done
  done
else
  volume_count=$(jq '. | length' "${TMP_DIR}/${RESOURCE_GROUP_NAME}.volumes")

  if [[ "${volume_count}" -eq 1 ]]; then
    echo "1 volume found in the resource group and purge_volumes is not set to true." >&2
  else
    echo "${volume_count} volumes found in the resource group and purge_volumes is not set to true." >&2
  fi
  echo -e "  Manually clean up the volumes with the following - ${WHITE}purge-volumes.sh ${RESOURCE_GROUP_NAME} true${NC}" >&2

  exit 1
fi
