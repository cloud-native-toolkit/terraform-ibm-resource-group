
locals {
  tmp_dir = "${path.cwd}/.tmp/resource-group"
  automation_tag = "automation:${random_uuid.tag.result}"
}

resource null_resource wait_for_sync {
  provisioner "local-exec" {
    command = "echo 'Sync: ${var.sync != null ? var.sync : ""}'"
  }
}

module "clis" {
  source = "cloud-native-toolkit/clis/util"
  version = "1.16.2"
}

resource "random_uuid" "tag" {
}

resource null_resource resource_group {
  depends_on = [null_resource.wait_for_sync, module.clis]

  triggers = {
    IBMCLOUD_API_KEY = base64encode(var.ibmcloud_api_key)
    RESOURCE_GROUP_NAME  = var.resource_group_name
    AUTOMATION_TAG  = local.automation_tag
    BIN_DIR = module.clis.bin_dir
  }

  provisioner "local-exec" {
    when        = create
    command = "${path.module}/scripts/create-resource-group.sh"
    environment = {
      IBMCLOUD_API_KEY = base64decode(self.triggers.IBMCLOUD_API_KEY)
      RESOURCE_GROUP_NAME  = self.triggers.RESOURCE_GROUP_NAME
      AUTOMATION_TAG  = self.triggers.AUTOMATION_TAG
      BIN_DIR = self.triggers.BIN_DIR
    }
  }

  provisioner "local-exec" {
    when        = destroy
    command = "${path.module}/scripts/delete-resource-group.sh"
    environment = {
      IBMCLOUD_API_KEY = base64decode(self.triggers.IBMCLOUD_API_KEY)
      RESOURCE_GROUP_NAME  = self.triggers.RESOURCE_GROUP_NAME
      AUTOMATION_TAG  = self.triggers.AUTOMATION_TAG
      BIN_DIR = self.triggers.BIN_DIR
    }
  }
}

data ibm_resource_group resource_group {
  depends_on = [null_resource.wait_for_sync, null_resource.resource_group]

  name  = var.resource_group_name
}

data ibm_resource_tag resource_group_tags {
  resource_id = data.ibm_resource_group.resource_group.crn
}

resource null_resource volumes {
  depends_on = [null_resource.wait_for_sync, null_resource.resource_group]

  triggers = {
    resource_group_name = var.resource_group_name
    purge_volumes       = var.purge_volumes
    automation_tag      = local.automation_tag
    ibmcloud_api_key    = var.ibmcloud_api_key
    bin_dir             = module.clis.bin_dir
    tmp_dir             = local.tmp_dir
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/purge-volumes.sh '${self.triggers.resource_group_name}' '${self.triggers.purge_volumes}'"

    environment = {
      IBMCLOUD_API_KEY = self.triggers.ibmcloud_api_key
      AUTOMATION_TAG = self.triggers.automation_tag
      BIN_DIR = self.triggers.bin_dir
      TMP_DIR = self.triggers.tmp_dir
    }
  }
}
