
resource null_resource wait_for_sync {
  provisioner "local-exec" {
    command = "echo 'Sync: ${var.sync != null ? var.sync : ""}'"
  }
}

module "clis" {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
}

resource "random_uuid" "tag" {
}

resource null_resource resource_group {
  count = var.provision ? 1 : 0
  depends_on = [null_resource.wait_for_sync, module.clis]

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-resource-group.sh"
    environment = {
      IBMCLOUD_API_KEY = var.ibmcloud_api_key
      RESOURCE_GROUP_NAME  = var.resource_group_name
      AUTOMATION_TAG  = "automation:${random_uuid.tag.result}"
      BIN_DIR = module.clis.bin_dir
    }
  }
}



data ibm_resource_group resource_group {
  depends_on = [null_resource.wait_for_sync, null_resource.resource_group]

  name  = var.resource_group_name
}
