
module "volume" {
  count = var.create_volume == "true" ? 1 : 0
  source = "./submodules/volume"

  region = var.region
  resource_group_name = module.resource_group2.name
  ibmcloud_api_key = var.ibmcloud_api_key
}
