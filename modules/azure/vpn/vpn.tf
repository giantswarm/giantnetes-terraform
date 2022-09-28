locals {
  tags = var.additional_tags
}

resource "azurerm_public_ip" "public_ip" {
  count               = var.vpn_enabled
  name                = "${var.cluster_name}-vpn-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.tags
}

resource "azurerm_virtual_network_gateway" "gateway" {
  count               = var.vpn_enabled
  name                = "${var.cluster_name}-vpn-gateway"
  location            = var.location
  resource_group_name = var.resource_group_name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false

  # SKU details can be found here
  # https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpngateways
  sku = "VpnGw1"

  ip_configuration {
    name                          = "${var.cluster_name}-vpn-gateway-ip-config"
    public_ip_address_id          = azurerm_public_ip.public_ip[count.index].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.subnet_id
  }

  tags = local.tags
}

resource "azurerm_local_network_gateway" "local_gateway_0" {
  count               = var.vpn_enabled
  name                = "${var.cluster_name}-vpn-right-gateway-0"
  location            = var.location
  resource_group_name = var.resource_group_name
  gateway_address     = var.vpn_right_gateway_address_0
  address_space       = [var.vpn_right_subnet_cidr_0]

  tags = local.tags
}

resource "azurerm_local_network_gateway" "local_gateway_1" {
  count               = var.vpn_enabled
  name                = "${var.cluster_name}-vpn-right-gateway-1"
  location            = var.location
  resource_group_name = var.resource_group_name
  gateway_address     = var.vpn_right_gateway_address_1
  address_space       = [var.vpn_right_subnet_cidr_1]

  tags = local.tags
}

resource "azurerm_virtual_network_gateway_connection" "vpn-connection-0" {
  count               = var.vpn_enabled
  name                = "${var.cluster_name}-vpn-connection-0"
  location            = var.location
  resource_group_name = var.resource_group_name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gateway[0].id
  local_network_gateway_id   = azurerm_local_network_gateway.local_gateway_0[0].id

  shared_key = var.vpn_shared_key
}

resource "azurerm_virtual_network_gateway_connection" "vpn-connection-1" {
  count               = var.vpn_enabled
  name                = "${var.cluster_name}-vpn-connection-1"
  location            = var.location
  resource_group_name = var.resource_group_name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gateway[0].id
  local_network_gateway_id   = azurerm_local_network_gateway.local_gateway_1[0].id

  shared_key = var.vpn_shared_key
}
