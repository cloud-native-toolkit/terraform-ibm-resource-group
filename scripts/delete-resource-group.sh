#!/bin/bash

set -e

PATH=$BIN_DIR:$PATH
JQ="$BIN_DIR/jq"

IAM_TOKEN=$(curl -s -X POST "https://iam.cloud.ibm.com/identity/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=${IBMCLOUD_API_KEY}" | ${JQ} -r '.access_token')

ACCOUNT_ID=$(curl -s -X GET 'https://iam.cloud.ibm.com/v1/apikeys/details' \
  -H "Authorization: Bearer $IAM_TOKEN" -H "IAM-Apikey: ${IBMCLOUD_API_KEY}" \
  -H 'Content-Type: application/json' | ${JQ} -r '.account_id')

# check if resource group exists

RESULT=$(curl -s --url "https://resource-controller.cloud.ibm.com/v2/resource_groups?account_id=$ACCOUNT_ID&name=$RESOURCE_GROUP_NAME"  \
  --header "Authorization: Bearer $IAM_TOKEN" \
  --header 'Content-Type: application/json')

COUNT=$(echo $RESULT | jq '.resources | length' -r)

if [ "$COUNT" -gt "0" ]; then
  echo "Deleting resource group $RESOURCE_GROUP_NAME..."
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

    curl -X DELETE https://resource-controller.cloud.ibm.com/v2/resource_groups/$RG_ID \
      --header "Authorization: Bearer $IAM_TOKEN" \
      --header 'Content-Type: application/json'
    echo "Deleted"
  fi
else
  echo "Resource Group Not Found"
  exit 1;
fi



######
# todo: ...
# label if created by this module, so we know to delete (use cloud tag)
# also get rid of provision flag