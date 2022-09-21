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
  required_version = ">= 0.13"
}
