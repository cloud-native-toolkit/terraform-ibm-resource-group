variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api key"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "sync" {
  type        = string
  description = "Value used to order the provisioning of the resource group"
  default     = ""
}
