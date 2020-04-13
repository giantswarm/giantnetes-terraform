locals {
  customer_vpn_subnets = var.customer_vpn_subnets != "" ? split(",", var.customer_vpn_subnets) : []
  k8s_api_external_access_whitelist = concat(["${var.external_ipsec_public_ip_0}/32", "${var.external_ipsec_public_ip_1}/32"], local.customer_vpn_subnets)
}

resource "azurerm_network_security_group" "worker" {
  name                = "${var.cluster_name}-worker"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    GiantSwarmInstallation = "${var.cluster_name}"
  }
}

resource "azurerm_subnet_network_security_group_association" "worker" {
  subnet_id                 = azurerm_subnet.worker_subnet.id
  network_security_group_id = azurerm_network_security_group.worker.id
}

resource "azurerm_network_security_rule" "master_ingress_api_internal" {
  name                        = "${var.cluster_name}-master-in-api-int"
  description                 = "${var.cluster_name} master - API internal access for whitelisted subnets"
  priority                    = 500
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.worker.name
}

resource "azurerm_network_security_rule" "master_ingress_api_external" {
  name                        = "${var.cluster_name}-master-in-api-ext"
  description                 = "${var.cluster_name} master - API external access for whitelisted subnets"
  priority                    = 550
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefixes     = [
      for ip in local.k8s_api_external_access_whitelist:
      length(regexall(".*\\/.*", ip)) == 1 ? ip : format("%s/32", ip)
    ]
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.worker.name
}

resource "azurerm_network_security_rule" "master_ingress_ingress" {
  name                        = "${var.cluster_name}-master-in-ingress"
  description                 = "${var.cluster_name} master - ingress allow for all"
  priority                    = 600
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "30010-30011"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.worker.name
}

resource "azurerm_network_security_rule" "worker_ingress_internal_any" {
  name                        = "${var.cluster_name}-worker-in-any"
  description                 = "${var.cluster_name} worker - Internal"
  priority                    = 700
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "10-65535"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.worker.name
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

  source_address_prefix       = var.vnet_cidr
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.worker.name
}
