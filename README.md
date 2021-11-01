# IBM Cloud Resource Group module

Terraform module to create a resource groups in an IBM Cloud account.

## Software dependencies

The module depends on the following software components:

### Command-line tools

- terraform - v13

### Terraform providers

- IBM Cloud provider >= 1.17.0

## Example usage

```hcl-terraform
terraform {
  required_providers {
    ibm = {
      source = "ibm-cloud/ibm"
    }
  }
  required_version = ">= 0.13"
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "ibmcloud_api_key" {
  type        = string
  description = "IBM Cloud API Key"
}

variable "resource_group_provision" {
  type        = bool
  description = "Flag indicating that the resource group should be provisioned"
  default     = true
}

module "resource_group" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-resource-group.git"

  resource_group_name = var.resource_group_name
  provision           = var.resource_group_provision
}
```
