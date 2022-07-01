#!/bin/bash

set -e

PATH=$BIN_DIR:$PATH
JQ="$BIN_DIR/jq"



# uses a semaphore to mitigate parallel execution problems
SEMAPHORE="resource-group.semaphore"

while true; do
  echo "Checking for semaphore"
  if [[ ! -f "${SEMAPHORE}" ]]; then
    echo -n "Resource Group $RESOURCE_GROUP_NAME" > "${SEMAPHORE}"

    if [[ $(cat ${SEMAPHORE}) == "Resource Group $RESOURCE_GROUP_NAME" ]]; then
      echo "Got the semaphore. Creating resource group"
      break
    fi
  fi

  SLEEP_TIME=$((1 + $RANDOM % 10))
  echo "  Waiting $SLEEP_TIME seconds for semaphore"
  sleep $SLEEP_TIME
done

function finish {
  rm -f "${SEMAPHORE}"
}

trap finish EXIT

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
  echo "Resource group $RESOURCE_GROUP_NAME already exists"
else
  echo "Creating resource group $RESOURCE_GROUP_NAME..."

  PAYLOAD="{ \"account_id\": \"$ACCOUNT_ID\", \"name\": \"$RESOURCE_GROUP_NAME\" }"
  echo $PAYLOAD

  # Submit request to IAM policy service
  RESPONSE=$(curl -s -w "\n%{http_code}" --request POST  --url https://resource-controller.cloud.ibm.com/v2/resource_groups  \
    --header "Authorization: Bearer $IAM_TOKEN" \
    --header 'Content-Type: application/json' \
    --data "$PAYLOAD")

  HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
  RESULT=$(sed '$ d' <<< "$RESPONSE")

  echo "HTTP_STATUS: $HTTP_STATUS"
  echo "RESULT: $RESULT"

  # if HTTP_STATUS starts with "20" (200/201), then request was successful.
  if [[ $HTTP_STATUS != "20"* ]];
  then
    echo "Resource group creation failed with HTTP Status: $HTTP_STATUS"
    exit 1
  fi

  RESOURCE_CRN=$(echo $RESULT | jq '.crn' -r)

  # tag the resource so that we know it was created by THIS script
  PAYLOAD="{ \"resources\": [{ \"resource_id\": \"$RESOURCE_CRN\" }], \"tag_names\": [\"$AUTOMATION_TAG\"] }"

  TAG_RESULT=$(curl -s -X POST \
    --header "Authorization: Bearer $IAM_TOKEN" \
    --header "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "https://tags.global-search-tagging.cloud.ibm.com/v3/tags/attach?tag_type=user")

  echo "Resource group created and tagged"
fi