resource "azurerm_key_vault" "vault" {
  name                        = "gs-${var.cluster_name}-vault"
  location                    = "${var.location}"
  resource_group_name         = "${var.resource_group_name}"
  enabled_for_deployment      = false
  enabled_for_disk_encryption = false
  tenant_id                   = "${var.tenant_id}"

  sku {
    name = "standard"
  }

  tags {
    Name                   = "${var.cluster_name}"
    GiantSwarmInstallation = "${var.cluster_name}"
  }
}

resource "azurerm_key_vault_access_policy" "runner" {
  vault_name          = "${azurerm_key_vault.vault.name}"
  resource_group_name = "${var.resource_group_name}"

  tenant_id = "${var.tenant_id}"
  object_id = "${var.terraform_group_id}"

  key_permissions = [
    "get",
    "list",
    "create",
    "delete",
  ]
}

resource "azurerm_key_vault_access_policy" "vault" {
  vault_name          = "${azurerm_key_vault.vault.name}"
  resource_group_name = "${var.resource_group_name}"

  tenant_id = "${var.tenant_id}"
  object_id = "${var.vault_vm_objectid == "" ? azurerm_virtual_machine.vault.id : var.vault_vm_objectid}"

  key_permissions = [
    "get",
    "list",
    "create",
    "delete",
    "decrypt",
    "encrypt",
    "update",
    "wrapKey",
    "unwrapKey",
  ]
}

resource "azurerm_key_vault_key" "generated" {
  name         = "${var.cluster_name}-vault-unseal-key"
  key_vault_id = "${azurerm_key_vault.vault.id}"
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}
