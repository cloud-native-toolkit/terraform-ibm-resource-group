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
module "resource_groups" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-resource-group.git?ref=v2.2.1"

  resource_group_name = var.resource_group_name
  ibmcloud_api_key    = var.ibmcloud_api_key
}
```
