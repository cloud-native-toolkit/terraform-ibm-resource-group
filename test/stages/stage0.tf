terraform {
  required_providers {
    ibm = {
      source = "ibm-cloud/ibm"
    }
    clis = {
      source = "cloud-native-toolkit/clis"
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
