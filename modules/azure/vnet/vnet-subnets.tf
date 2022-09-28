locals {
  common_tags = var.additional_tags
}

resource "azurerm_virtual_network" "cluster_vnet" {
  name                = var.cluster_name
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_cidr]
  location            = var.location

  tags = merge(local.common_tags, map(
    "GiantSwarmInstallation", var.cluster_name
  ))
}

# NOTE: Using one subnet per role, because Azure does not have availability zones yet.
# They just released availability zones for public preview in two locations.
# https://azure.microsoft.com/en-us/updates/azure-availability-zones/

resource "azurerm_subnet" "vpn_subnet" {
  count = var.vpn_enabled ? 1 : 0

  # NOTE: Azure VPN gateway requires subnet name GatewaySubnet.
  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.cluster_vnet.name

  # Use first /27 for /16 (e.g. for 10.0.0.0/16 10.0.0.0/27 will be used).
  address_prefixes = [cidrsubnet(var.vnet_cidr, 11, 0)]
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "${var.cluster_name}_bastion_subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.cluster_vnet.name

  # NOTE: bastion_cidr should be unique across clusters, when VPN enabled.
  address_prefixes = [var.bastion_cidr]

}

resource "azurerm_subnet" "vault_subnet" {
  name                 = "${var.cluster_name}_vault_subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.cluster_vnet.name
  address_prefixes       = [cidrsubnet(var.vnet_cidr, 8, 1)]
}

resource "azurerm_subnet" "worker_subnet" {
  name                 = "${var.cluster_name}_worker_subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.cluster_vnet.name
  address_prefixes       = [cidrsubnet(var.vnet_cidr, 8, 2)]

  # We need the storage service endpoint to grant the control plane VNET access to the TC's storage accounts
  service_endpoints = ["Microsoft.Storage"]
}

resource "azurerm_subnet_route_table_association" "worker" {
  subnet_id      = azurerm_subnet.worker_subnet.id
  route_table_id = azurerm_route_table.worker_rt.id
}
