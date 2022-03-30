resource "azurerm_lb" "api_lb_internal" {
  name                = "${var.cluster_name}-cluster-lb-internal"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "api-internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.worker_subnet.id
  }

  tags = merge(local.common_tags, map(
    "GiantSwarmInstallation", var.cluster_name
  ))

  lifecycle {
    # Needed to upgrade azurerm provider to 3.x to avoid the load balancer from being recreated.
    ignore_changes = [frontend_ip_configuration.0.zones]
  }
}

resource "azurerm_dns_a_record" "api_dns_internal" {
  name                = var.api_dns_internal
  zone_name           = var.base_domain
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_lb.api_lb_internal.private_ip_address]
}

resource "azurerm_lb_backend_address_pool" "api-lb-internal" {
  name                = "api-lb-pool-internal"
  loadbalancer_id     = azurerm_lb.api_lb_internal.id
}

resource "azurerm_lb_probe" "api_lb_internal" {
  name                = "api-lb-internal-probe-443-up"
  loadbalancer_id     = azurerm_lb.api_lb_internal.id
  protocol            = "Http"
  port                = 8089
  request_path        = "/healthz"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "api_lb_internal" {
  name                     = "api-lb-internal-rule-443-443"
  loadbalancer_id          = azurerm_lb.api_lb_internal.id
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.api-lb-internal.id]
  probe_id                 = azurerm_lb_probe.api_lb_internal.id

  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "api-internal"
}

