terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "= 2.96.0"
    }
    gotemplate = {
      source = "giantswarm.io/operations/gotemplate"
      version = "= 0.4.0"
    }
    http = {
      source = "hashicorp/http"
    }
    ignition = {
      source = "terraform-providers/ignition"
    }
  }
  required_version = ">= 0.13"
}
