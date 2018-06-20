resource "azurerm_public_ip" "public_ip" {
  count                        = "${var.vpn_enabled}"
  name                         = "${var.cluster_name}-vpn-public-ip"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "gateway" {
  count               = "${var.vpn_enabled}"
  name                = "${var.cluster_name}-vpn-gateway"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false

  # SKU details can be found here
  # https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpngateways
  sku = "VpnGw1"

  ip_configuration {
    name                          = "${var.cluster_name}-vpn-gateway-ip-config"
    public_ip_address_id          = "${azurerm_public_ip.public_ip.id}"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${var.subnet_id}"
  }
}

resource "azurerm_local_network_gateway" "local_gateway" {
  count               = "${var.vpn_enabled}"
  name                = "${var.cluster_name}-vpn-right-gateway"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  gateway_address     = "${var.vpn_right_gateway_address}"
  address_space       = ["${var.vpn_right_subnet_cidr}"]
}
