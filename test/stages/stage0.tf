terraform {
  required_providers {
    ibm = {
      source = "ibm-cloud/ibm"
      version = ">= 1.17.0"
    }
    clis = {
      source = "cloud-native-toolkit/clis"
      version = ">= 0.2.0"
    }
  }
}

data clis_check clis {
  clis = ["ibmcloud"]
}

resource local_file bin_dir {
  filename = "${path.cwd}/.bin_dir"

  content = data.clis_check.clis.bin_dir
}
