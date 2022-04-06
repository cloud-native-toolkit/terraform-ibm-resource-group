output "name" {
  description = "The name of the resource group"
  value       = var.resource_group_name
  depends_on  = [data.ibm_resource_group.resource_group]
}

output "id" {
  description = "The id of the resource group"
  value       = data.ibm_resource_group.resource_group.id
}

output "group" {
  description = "The resource group object"
  value       = data.ibm_resource_group.resource_group
}

output "sync" {
  description = "Value used to order the provisioning of the resource group"
  value       = var.resource_group_name
  depends_on  = [data.ibm_resource_group.resource_group]
}

output "provision" {
  description = "Flag indicating that the resource group was provisioned by this module"
  value       = contains(data.ibm_resource_tag.resource_group_tags.tags, local.automation_tag)
}
