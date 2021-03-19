terraform {
  required_version = ">= 0.13"

  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
      version = "3.1.1"
    }
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "1.24.3"
    }
  }
}
