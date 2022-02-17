output "name" {
  description = "The name of the resource group"
  value       = var.resource_group_name
  depends_on  = [data.ibm_resource_group.resource_group]
}

output "id" {
  description = "The id of the resource group"
  value       = length(data.ibm_resource_group.resource_group) > 0 ? data.ibm_resource_group.resource_group[0].id : ""
}

output "group" {
  description = "The resource group object"
  value       = length(data.ibm_resource_group.resource_group) > 0 ? data.ibm_resource_group.resource_group[0] : {}
}

output "provision" {
  description = "Flag indicating whether the resource group was provisioned"
  value       = var.provision
}

output "sync" {
  description = "Value used to order the provisioning of the resource group"
  value       = var.resource_group_name
  depends_on  = [data.ibm_resource_group.resource_group]
}
