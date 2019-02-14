provider "azurerm" {
  version = "=1.22.0"

  environment = "${var.azure_cloud}"
}

data "azurerm_client_config" "current" {}
