module "resource_group1" {
  source = "./module"

  resource_group_name = "test-resource-group1"
  provision           = var.resource_group_provision
}

module "resource_group2" {
  source = "./module"

  resource_group_name = "test-resource-group2"
  provision           = var.resource_group_provision
  sync                = module.resource_group1.sync
}

resource "null_resource" "print_rg" {
  provisioner "local-exec" {
    command = "echo -n '${module.resource_group2.name}' > .rg_name"
  }
}
