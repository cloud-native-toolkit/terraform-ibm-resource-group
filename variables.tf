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

variable "purge_volumes" {
  type        = bool
  description = "Flag indicating that any volumes in the resource group should be automatically destroyed before destroying the resource group. If volumes exist and the flag is false then the destroy will fail."
  default     = false
}
