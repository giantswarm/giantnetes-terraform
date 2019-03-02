resource "azurerm_key_vault" "vault" {
  name                        = "giantswarm-${var.cluster_name}-vault"
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

  access_policy {
    tenant_id = "${var.tenant_id}"
    object_id = "${azurerm_virtual_machine.vault.id}"

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

  network_acls {
    default_action = "Deny"
    bypass         = "None"
    virtual_network_subnet_ids = ["${var.vault_subnet}"]
  }
}


resource "azurerm_key_vault_key" "generated" {
  name      = "${var.cluster_name}-vault-unseal-key"
  vault_uri = "${azurerm_key_vault.vault.vault_uri}"
  key_type  = "RSA"
  key_size  = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}
