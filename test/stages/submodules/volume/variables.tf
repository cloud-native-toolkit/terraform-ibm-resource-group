
variable "region" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "ibmcloud_api_key" {
  type = string
  sensitive = true
}
