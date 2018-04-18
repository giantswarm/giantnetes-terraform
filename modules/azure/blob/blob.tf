resource "azurerm_storage_account" "storage_acc" {
  name                     = "${var.cluster_name}machine"
  resource_group_name      = "${var.resource_group_name}"
  location                 = "${var.azure_location}"
  account_kind             = "BlobStorage"
  account_tier             = "Cool"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "ignition" {
  name                  = "ignition"
  resource_group_name   = "${var.resource_group_name}"
  storage_account_name  = "${azurerm_storage_account.storage_acc.name}"
  container_access_type = "container"
}

output "blob_storage_account" {
  value = "${azurerm_storage_account.storage_acc.name}"
}

output "blob_storage_container" {
  value = "${azurerm_storage_container.ignition.name}"
}
