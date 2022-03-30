resource "azurerm_public_ip" "ingress_ip" {
  name                = "${var.cluster_name}_ingress_ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(local.common_tags, map(
    "GiantSwarmInstallation", var.cluster_name
  ))
}

# We need explicitly add this entry for apps like happa.g8s.<base> to be working.
# In Azure this is required (not needed in AWS) and looks like it's aligned with RFC.
# https://tools.ietf.org/html/rfc1034#section-4.3.3
resource "azurerm_dns_a_record" "g8s_wildcard_dns" {
  name                = "*.${var.api_dns}"
  zone_name           = var.base_domain
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_public_ip.ingress_ip.ip_address]
}

resource "azurerm_dns_a_record" "ingress_wildcard_dns" {
  name                = "*"
  zone_name           = var.base_domain
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_public_ip.ingress_ip.ip_address]
}

resource "azurerm_lb_rule" "ingress_http_lb" {
  name                     = "ingress-lb-rule-80-30010"
  loadbalancer_id          = azurerm_lb.api_lb.id
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.api-lb.id]
  probe_id                 = azurerm_lb_probe.ingress_30010_lb.id

  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 30010
  frontend_ip_configuration_name = "ingress"
}

resource "azurerm_lb_probe" "ingress_30010_lb" {
  name                = "ingress-lb-probe-30010-up"
  loadbalancer_id     = azurerm_lb.api_lb.id
  protocol            = "Tcp"
  port                = 30010
}

resource "azurerm_lb_rule" "ingress_https_lb" {
  name                     = "ingress-lb-rule-443-30011"
  loadbalancer_id          = azurerm_lb.api_lb.id
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.api-lb.id]
  probe_id                 = azurerm_lb_probe.ingress_30011_lb.id

  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 30011
  frontend_ip_configuration_name = "ingress"
}

resource "azurerm_lb_probe" "ingress_30011_lb" {
  name                = "ingress-lb-probe-30011-up"
  loadbalancer_id     = azurerm_lb.api_lb.id
  protocol            = "Tcp"
  port                = 30011
  interval_in_seconds = 5
  number_of_probes    = 2
}

# Azure requires the probe to be associated with a load balancer the VMSS belongs to.
# This probe has to be referenced by an active forwarding rule.
# Since we don't want to expose SSH through the load balancer, we use random port 65000.
resource "azurerm_lb_rule" "ingress_ssh_lb" {
  name                     = "ingress-lb-fake-rule-for-node-health"
  loadbalancer_id          = azurerm_lb.api_lb.id
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.api-lb.id]
  probe_id                 = azurerm_lb_probe.kubelet.id

  protocol                       = "Udp"
  frontend_port                  = 65000
  backend_port                   = 65000
  frontend_ip_configuration_name = "ingress"
}

# TODO delete this once deployed in all azure MCs.
resource "azurerm_lb_rule" "ingress_ssh_lb_legacy" {
  name                     = "ingress-lb-fake-rule-for-node-health-legacy"
  loadbalancer_id          = azurerm_lb.api_lb.id
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.api-lb.id]
  probe_id                 = azurerm_lb_probe.ssh.id

  protocol                       = "Udp"
  frontend_port                  = 65001
  backend_port                   = 65001
  frontend_ip_configuration_name = "ingress"
}

# TODO delete this once deployed in all azure MCs.
resource "azurerm_lb_probe" "ssh" {
  name                = "ssh-probe"
  loadbalancer_id     = azurerm_lb.api_lb.id
  protocol            = "Tcp"
  port                = 22
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_probe" "kubelet" {
  name                = "kubelet-healthz-probe"
  loadbalancer_id     = azurerm_lb.api_lb.id
  protocol            = "Http"
  port                = 10248
  request_path        = "/healthz"
  interval_in_seconds = 5
  number_of_probes    = 2
}
