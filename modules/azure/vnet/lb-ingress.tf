resource "azurerm_public_ip" "ingress_ip" {
  name                         = "${var.cluster_name}_ingress_ip"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${var.ingress_dns}"

  tags {
    Environment = "${var.cluster_name}"
  }
}

resource "azurerm_dns_a_record" "ingress_dns" {
  name                = "${var.ingress_dns}"
  zone_name           = "${var.base_domain}"
  resource_group_name = "${var.resource_group_name}"
  ttl                 = 300
  records             = ["${azurerm_public_ip.ingress_ip.ip_address}"]
}

resource "azurerm_lb_backend_address_pool" "ingress-lb" {
  name                = "ingress-lb-pool"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.cluster_lb.id}"
}

resource "azurerm_lb_rule" "ingress_http_lb" {
  name                    = "ingress-lb-rule-80-30010"
  resource_group_name     = "${var.resource_group_name}"
  loadbalancer_id         = "${azurerm_lb.cluster_lb.id}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.ingress-lb.id}"
  probe_id                = "${azurerm_lb_probe.ingress_30010_lb.id}"

  protocol                       = "tcp"
  frontend_port                  = 80
  backend_port                   = 30010
  frontend_ip_configuration_name = "ingress"
}

resource "azurerm_lb_probe" "ingress_30010_lb" {
  name                = "ingress-lb-probe-30011-up"
  loadbalancer_id     = "${azurerm_lb.cluster_lb.id}"
  resource_group_name = "${var.resource_group_name}"
  protocol            = "tcp"
  port                = 30010
}

resource "azurerm_lb_rule" "ingress_https_lb" {
  name                    = "ingress-lb-rule-443-30011"
  resource_group_name     = "${var.resource_group_name}"
  loadbalancer_id         = "${azurerm_lb.cluster_lb.id}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.ingress-lb.id}"
  probe_id                = "${azurerm_lb_probe.ingress_30011_lb.id}"

  protocol                       = "tcp"
  frontend_port                  = 443
  backend_port                   = 30011
  frontend_ip_configuration_name = "ingress"
}

resource "azurerm_lb_probe" "ingress_30011_lb" {
  name                = "ingress-lb-probe-30011-up"
  loadbalancer_id     = "${azurerm_lb.cluster_lb.id}"
  resource_group_name = "${var.resource_group_name}"
  protocol            = "tcp"
  port                = 30011
}
