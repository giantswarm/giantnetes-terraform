resource "azurerm_network_security_group" "bastion" {
  name                = "${var.cluster_name}-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    GiantSwarmInstallation = "${var.cluster_name}"
  }
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = azurerm_subnet.bastion_subnet.id
  network_security_group_id = azurerm_network_security_group.bastion.id
}

resource "azurerm_network_security_rule" "bastion_ingress_ssh" {
  name                   = "${var.cluster_name}-bastion-ssh"
  description            = "${var.cluster_name} bastion - SSH"
  priority               = 500
  direction              = "Inbound"
  access                 = "Allow"
  protocol               = "TCP"
  source_port_range      = "*"
  destination_port_range = "22"

  source_address_prefix       = "*"
  destination_address_prefix  = var.vnet_cidr
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.bastion.name
}

resource "azurerm_network_security_rule" "bastion_ingress_internal_any" {
  name                        = "${var.cluster_name}-bastion-in-any"
  description                 = "${var.cluster_name} bastion - Internal"
  priority                    = 600
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "10-65535"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.bastion.name
}

resource "azurerm_network_security_rule" "bastion_egress" {
  name                   = "${var.cluster_name}-bastion-out"
  description            = "${var.cluster_name} bastion - Outbound"
  priority               = 700
  direction              = "Outbound"
  access                 = "Allow"
  protocol               = "*"
  source_port_range      = "*"
  destination_port_range = "*"

  source_address_prefix       = var.vnet_cidr
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.bastion.name
}
