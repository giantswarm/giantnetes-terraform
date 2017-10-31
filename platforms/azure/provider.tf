terraform {
  backend "azurerm" {}
}

provider "azurerm" {
  environment = "${var.azure_cloud}"
}

data "azurerm_client_config" "current" {}
