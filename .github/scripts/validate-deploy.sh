#!/usr/bin/env bash

RESOURCE_GROUP_NAME=$(cat .rg_name)

if ! ibmcloud resource group "${RESOURCE_GROUP_NAME}" -q; then
  echo "Resource group not found: ${RESOURCE_GROUP_NAME}"
  exit 1
fi
