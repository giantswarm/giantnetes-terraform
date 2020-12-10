terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    gotemplate = {
      source = "giantswarm.io/operations/gotemplate"
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
