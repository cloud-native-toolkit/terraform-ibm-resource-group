module "resource_group1" {
  source = "./module"

  resource_group_name = "test-resource-group1"
  provision           = var.resource_group_provision
  enabled             = var.enabled
}

module "resource_group2" {
  source = "./module"

  resource_group_name = "test-resource-group2"
  provision           = var.resource_group_provision
  sync                = module.resource_group1.sync
  enabled             = var.enabled
}
