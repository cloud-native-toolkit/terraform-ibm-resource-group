#!/usr/bin/env bash

BIN_DIR=$(cat .bin_dir)
RESOURCE_GROUP_NAME=$(cat .rg_name)

REGION=$(cat terraform.tfvars | grep -E "^region" | sed "s/region=//g" | sed 's/"//g')

${BIN_DIR}/ibmcloud login -r "${REGION}" --apikey "${IBMCLOUD_API_KEY}"

if ! ${BIN_DIR}/ibmcloud resource group "${RESOURCE_GROUP_NAME}" -q; then
  echo "Resource group not found: ${RESOURCE_GROUP_NAME}"
  exit 1
fi
