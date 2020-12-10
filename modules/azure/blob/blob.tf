resource "azurerm_storage_account" "storage_acc" {
  name                      = "${var.cluster_name}config"
  location                  = var.azure_location
  account_kind              = "BlobStorage"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  resource_group_name       = var.resource_group_name
}

resource "azurerm_storage_container" "ignition" {
  name                  = "ignition"
  storage_account_name  = azurerm_storage_account.storage_acc.name
  container_access_type = "private"
}

output "storage_acc" {
  value = azurerm_storage_account.storage_acc.name
}

output "storage_acc_url" {
  value = azurerm_storage_account.storage_acc.primary_connection_string
}

output "storage_container" {
  value = azurerm_storage_container.ignition.name
}
