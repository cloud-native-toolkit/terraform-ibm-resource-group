variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api token"
}

variable "provision" {
  type        = bool
  description = "Flag indicating that the resource group should be created"
  default     = true
}

variable "sync" {
  type        = string
  description = "Value used to order the provisioning of the resource group"
  default     = ""
}
