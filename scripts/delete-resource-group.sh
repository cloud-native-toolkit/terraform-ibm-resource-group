#!/bin/bash

set -e

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
RG_ID=$(echo $RESULT | jq '.resources[].id' -r)
RG_CRN=$(echo $RESULT | jq '.resources[].crn' -r)
echo "ID: $RG_ID"
echo "CRN: $RG_CRN"

#check to make sure the RG has the automation tag before deleting
TAGS=$(curl -s -X GET \
  --header "Authorization: Bearer $IAM_TOKEN" \
  --header 'Content-Type: application/json' \
  "https://tags.global-search-tagging.cloud.ibm.com/v3/tags?tag_type=user&providers=ghost&offset=0&limit=10&order_by_name=asc&attached_to=$RG_CRN")

if [[ "$TAGS" == *"$AUTOMATION_TAG"* ]]; then
  echo "Found automation tag: $AUTOMATION_TAG. Deleting resource group $RG_ID..."

  RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE https://resource-controller.cloud.ibm.com/v2/resource_groups/$RG_ID \
    --header "Authorization: Bearer $IAM_TOKEN" \
    --header 'Content-Type: application/json')

  HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
  RESULT=$(sed '$ d' <<< "$RESPONSE")

  echo "HTTP_STATUS: $HTTP_STATUS"
  echo "RESULT: $RESULT"

  # if HTTP_STATUS starts with "20" (200/201), then request was successful.
  if [[ $HTTP_STATUS != "20"* ]];
  then
    echo "Resource group deletion failed with HTTP Status: $HTTP_STATUS"
    exit 1
  fi

  echo "Deleted"
fi
