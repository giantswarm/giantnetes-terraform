terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    ignition = {
      source = "terraform-providers/ignition"
    }
    local = {
      source = "hashicorp/local"
    }
  }
  required_version = ">= 0.13"
}
