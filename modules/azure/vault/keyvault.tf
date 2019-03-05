resource "azurerm_key_vault" "vault" {
  count  = "${var.terraform_group_id == "" ? 0 : 1}"
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

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

resource "azurerm_key_vault_access_policy" "runner" {
  count  = "${var.terraform_group_id == "" ? 0 : 1}"
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
  count  = "${var.terraform_group_id == "" ? 0 : 1}"
  vault_name          = "${azurerm_key_vault.vault.name}"
  resource_group_name = "${var.resource_group_name}"

  tenant_id = "${var.tenant_id}"
  object_id = "${azurerm_user_assigned_identity.vault.principal_id}"

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
  count  = "${var.terraform_group_id == "" ? 0 : 1}"
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
