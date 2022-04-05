module "existing_resource_group" {
  source = "./module"

  resource_group_name = "Default"
  ibmcloud_api_key    = var.ibmcloud_api_key
}

module "resource_group1" {
  source = "./module"

  resource_group_name = "test-resource-group1"
  ibmcloud_api_key    = var.ibmcloud_api_key
  sync                = module.existing_resource_group.sync
}

module "resource_group2" {
  source = "./module"

  resource_group_name = "test-resource-group2"
  sync                = module.resource_group1.sync
  ibmcloud_api_key    = var.ibmcloud_api_key
}

resource "null_resource" "print_rg" {
  provisioner "local-exec" {
    command = "echo -n '${module.resource_group2.name}' > .rg_name"
  }
}
