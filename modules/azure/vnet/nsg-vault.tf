resource "azurerm_network_security_group" "vault" {
  name                = "${var.cluster_name}-vault"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    GiantSwarmInstallation = var.cluster_name
  }
}

resource "azurerm_subnet_network_security_group_association" "vault" {
  subnet_id                 = azurerm_subnet.vault_subnet.id
  network_security_group_id = azurerm_network_security_group.vault.id
}

resource "azurerm_network_security_rule" "vault_ingress_ssh" {
  name                        = "${var.cluster_name}-vault-ssh"
  description                 = "${var.cluster_name} vault - SSH"
  priority                    = 500
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = var.vnet_cidr
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.vault.name
}

resource "azurerm_network_security_rule" "vault_ingress_internal_8200" {
  name                        = "${var.cluster_name}-vault-in-8200"
  description                 = "${var.cluster_name} vault - internal 8200"
  priority                    = 600
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8200"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.vault.name
}

resource "azurerm_network_security_rule" "vault_ingress_node-exporter" {
  name                        = "${var.cluster_name}-vault-node-exporter"
  description                 = "${var.cluster_name} vault - node-exporter"
  priority                    = 700
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "10300"
  source_address_prefixes     = azurerm_subnet.worker_subnet.address_prefixes
  destination_address_prefix  = var.vnet_cidr
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.vault.name
}

resource "azurerm_network_security_rule" "vault_ingress_cert-exporter" {
  name                        = "${var.cluster_name}-vault-cert-exporter"
  description                 = "${var.cluster_name} vault - cert-exporter"
  priority                    = 800
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "9005"
  source_address_prefixes     = azurerm_subnet.worker_subnet.address_prefixes
  destination_address_prefix  = var.vnet_cidr
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.vault.name
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

  source_address_prefix       = var.vnet_cidr
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.vault.name
}
