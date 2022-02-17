
# Resource Group Variables
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

variable "enabled" {
}
