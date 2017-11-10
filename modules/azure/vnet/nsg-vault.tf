resource "azurerm_network_security_group" "vault" {
  name                = "${var.cluster_name}-vault"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  tags {
    Environment = "${var.cluster_name}"
  }
}

resource "azurerm_network_security_rule" "vault_ingress_ssh" {
  name                        = "${var.cluster_name}-vault-ssh"
  description                 = "${var.cluster_name} vault - SSH"
  priority                    = 500
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "${var.vnet_cidr}"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.vault.name}"
}

resource "azurerm_network_security_rule" "vault_ingress_internal_8200" {
  name                        = "${var.cluster_name}-vault-in-8200"
  description                 = "${var.cluster_name} vault - internal 8200"
  priority                    = 600
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "8200"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.vault.name}"
}

resource "azurerm_network_security_rule" "vault_egress" {
  name                   = "${var.cluster_name}-vault-out"
  description            = "${var.cluster_name} vault - Outbound"
  priority               = 700
  direction              = "Outbound"
  access                 = "Allow"
  protocol               = "*"
  source_port_range      = "*"
  destination_port_range = "*"

  source_address_prefix       = "${var.vnet_cidr}"
  destination_address_prefix  = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.vault.name}"
}
