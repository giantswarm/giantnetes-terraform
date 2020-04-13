locals {
  customer_vpn_subnets = var.customer_vpn_subnets != "" ? split(",", var.customer_vpn_subnets) : []
  k8s_api_external_access_whitelist = concat(["${var.external_ipsec_public_ip_0}/32", "${var.external_ipsec_public_ip_1}/32"], local.customer_vpn_subnets)
}

resource "azurerm_network_security_group" "master" {
  name                = "${var.cluster_name}-master"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    GiantSwarmInstallation = "${var.cluster_name}"
  }
}

resource "azurerm_subnet_network_security_group_association" "master" {
  subnet_id                 = azurerm_subnet.worker_subnet.id
  network_security_group_id = azurerm_network_security_group.master.id
}

resource "azurerm_network_security_rule" "master_k8s_api" {
  name                        = "${var.cluster_name}-master-k8s-api"
  description                 = "${var.cluster_name} master - API allow whitelisted networks"
  priority                    = 500
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
  network_security_group_name = azurerm_network_security_group.master.name
}

resource "azurerm_network_security_rule" "master_internal_any" {
  name                        = "${var.cluster_name}-master-in-any"
  description                 = "${var.cluster_name} master - Internal access"
  priority                    = 700
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "10-65535"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.master.name
}

resource "azurerm_network_security_rule" "master_egress" {
  name                   = "${var.cluster_name}-master-out"
  description            = "${var.cluster_name} master - Outbound"
  priority               = 600
  direction              = "Outbound"
  access                 = "Allow"
  protocol               = "*"
  source_port_range      = "*"
  destination_port_range = "*"

  source_address_prefix       = var.vnet_cidr
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.master.name
}
