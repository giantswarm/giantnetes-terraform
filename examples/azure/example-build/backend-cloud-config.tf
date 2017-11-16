terraform {
  backend "azurerm" {
    storage_account_name = "<cluster_name>terraform"
    container_name       = "<cluster_name>-state"
    key                  = "terraform-cloud-config"
  }
}
