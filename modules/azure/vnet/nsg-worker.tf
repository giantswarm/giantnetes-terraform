resource "azurerm_network_security_group" "worker" {
  name                = "${var.cluster_name}-worker"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  tags {
    Environment = "${var.cluster_name}"
  }
}

resource "azurerm_network_security_rule" "worker_ingress_internal_any" {
  name                        = "${var.cluster_name}-worker-in-any"
  description                 = "${var.cluster_name} worker - Internal"
  priority                    = 500
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "10-65535"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.worker.name}"
}

resource "azurerm_network_security_rule" "worker_egress" {
  name                   = "${var.cluster_name}-worker-out"
  description            = "${var.cluster_name} worker - Outbound"
  priority               = 600
  direction              = "Outbound"
  access                 = "Allow"
  protocol               = "*"
  source_port_range      = "*"
  destination_port_range = "*"

  source_address_prefix       = "${var.vnet_cidr}"
  destination_address_prefix  = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.worker.name}"
}
