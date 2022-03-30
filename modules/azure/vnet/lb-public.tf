resource "azurerm_lb" "api_lb" {
  name                = "${var.cluster_name}-cluster-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "api"
    public_ip_address_id          = azurerm_public_ip.api_ip.id
    private_ip_address_allocation = "Dynamic"
    private_ip_address_version    = "IPv4"
  }

  frontend_ip_configuration {
    name                          = "ingress"
    public_ip_address_id          = azurerm_public_ip.ingress_ip.id
    private_ip_address_allocation = "Dynamic"
    private_ip_address_version    = "IPv4"
  }

  tags = merge(local.common_tags, map(
    "GiantSwarmInstallation", var.cluster_name
  ))

  lifecycle {
    ignore_changes = [
      frontend_ip_configuration.0.private_ip_address_version,
      frontend_ip_configuration.1.private_ip_address_version
    ]
  }
}

resource "azurerm_public_ip" "api_ip" {
  name                = "${var.cluster_name}_api_ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(local.common_tags, map(
    "GiantSwarmInstallation", var.cluster_name
  ))
}

resource "azurerm_dns_a_record" "api_dns" {
  name                = var.api_dns
  zone_name           = var.base_domain
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_public_ip.api_ip.ip_address]
}

resource "azurerm_lb_backend_address_pool" "api-lb" {
  name                = "api-lb-pool"
  loadbalancer_id     = azurerm_lb.api_lb.id
}

resource "azurerm_lb_rule" "api_lb" {
  name                     = "api-lb-rule-443-443"
  loadbalancer_id          = azurerm_lb.api_lb.id
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.api-lb.id]
  probe_id                 = azurerm_lb_probe.api_lb.id

  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "api"
}

resource "azurerm_lb_probe" "api_lb" {
  name                = "api-lb-probe-443-up"
  loadbalancer_id     = azurerm_lb.api_lb.id
  protocol            = "Http"
  port                = 8089
  request_path        = "/healthz"
  interval_in_seconds = 5
  number_of_probes    = 2
}
