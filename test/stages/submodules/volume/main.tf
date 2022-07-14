
locals {
  name = "test-volume-${random_string.volume_id.result}"
}

resource null_resource print_name {
  provisioner "local-exec" {
    command = "echo 'Resource group: ${var.resource_group_name}'"
  }
}

data ibm_resource_group resource_group {
  depends_on = [null_resource.print_name]

  name  = var.resource_group_name
}

module "clis" {
  source = "cloud-native-toolkit/clis/util"
}

resource random_string volume_id {
  length = 4
  special = false
  upper = false
}

resource null_resource volume {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-volume.sh '${var.region}' '${local.name}' '${data.ibm_resource_group.resource_group.id}'"

    environment = {
      BIN_DIR = module.clis.bin_dir
      IBMCLOUD_API_KEY = nonsensitive(var.ibmcloud_api_key)
    }
  }
}
