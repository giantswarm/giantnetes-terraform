resource "azurerm_public_ip" "workers_egress_ip" {
  name                = "${var.cluster_name}-workers-egress-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    GiantSwarmInstallation = var.cluster_name
  }
}

resource "azurerm_nat_gateway" "workers_nat_gw" {
  name                = "${var.cluster_name}-workers-nat-gw"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Standard"

  tags = {
    GiantSwarmInstallation = var.cluster_name
  }
}

resource "azurerm_nat_gateway_public_ip_association" "workers-nat-gw-public-ip-association" {
  nat_gateway_id       = azurerm_nat_gateway.workers_nat_gw.id
  public_ip_address_id = azurerm_public_ip.workers_egress_ip.id
}

resource "azurerm_subnet_nat_gateway_association" "worker_subnet_nat_gw_association" {
  subnet_id      = azurerm_subnet.worker_subnet.id
  nat_gateway_id = azurerm_nat_gateway.workers_nat_gw.id
}
