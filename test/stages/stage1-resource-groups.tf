module "resource_group1" {
  source = "./module"

  resource_group_name = "test-resource-group1"
}

module "resource_group2" {
  source = "./module"

  resource_group_name = "test-resource-group2"
  sync                = module.resource_group1.sync
}
