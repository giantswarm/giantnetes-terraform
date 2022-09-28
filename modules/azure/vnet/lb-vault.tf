resource "azurerm_lb" "vault_lb" {
  name                = "${var.cluster_name}-vault-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name      = "vault"
    subnet_id = azurerm_subnet.vault_subnet.id
  }

  tags = merge(local.common_tags, map(
    "GiantSwarmInstallation", var.cluster_name
  ))
}

resource "azurerm_dns_a_record" "vault_dns" {
  name                = var.vault_dns
  zone_name           = var.base_domain
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_lb.vault_lb.private_ip_address]
}

resource "azurerm_lb_backend_address_pool" "vault-lb" {
  name                = "vault-lb-pool"
  loadbalancer_id     = azurerm_lb.vault_lb.id
}

resource "azurerm_lb_rule" "vault_lb" {
  name                     = "${var.cluster_name}-vault-lb-rule-443-8200"
  loadbalancer_id          = azurerm_lb.vault_lb.id
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.vault-lb.id]
  probe_id                 = azurerm_lb_probe.vault_lb.id

  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 8200
  frontend_ip_configuration_name = "vault"
}

resource "azurerm_lb_probe" "vault_lb" {
  name                = "${var.cluster_name}-vault-lb-probe-8200"
  loadbalancer_id     = azurerm_lb.vault_lb.id
  protocol            = "Tcp"
  port                = 8200
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_nat_gateway" "vault_nat_gateway" {
  name                    = "${var.cluster_name}-vault-nat-gateway"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_public_ip" "vault_nat_gw_public_ip" {
  name                = "${var.cluster_name}-vault-nat-gateway-publicIP"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "vault_nat_gw_ip_association" {
  nat_gateway_id       = azurerm_nat_gateway.vault_nat_gateway.id
  public_ip_address_id = azurerm_public_ip.vault_nat_gw_public_ip.id
}

resource "azurerm_subnet_nat_gateway_association" "vault_nat_gw_subnet_association" {
  subnet_id      = azurerm_subnet.vault_subnet.id
  nat_gateway_id = azurerm_nat_gateway.vault_nat_gateway.id
}
