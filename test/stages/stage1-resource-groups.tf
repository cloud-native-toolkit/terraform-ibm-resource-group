module "resource_group1" {
  source = "./module"

  resource_group_name = "test-resource-group1"
  ibmcloud_api_key    = var.ibmcloud_api_key
}

module "resource_group2" {
  source = "./module"

  resource_group_name = "test-resource-group2"
  ibmcloud_api_key    = var.ibmcloud_api_key
  sync                = module.resource_group1.sync
}
