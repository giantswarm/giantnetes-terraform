resource "azurerm_lb" "api_lb" {
  name                = "${var.cluster_name}-cluster-lb"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  frontend_ip_configuration {
    name                          = "api"
    public_ip_address_id          = "${azurerm_public_ip.api_ip.id}"
    private_ip_address_allocation = "dynamic"
  }

  tags {
    GiantSwarmInstallation = "${var.cluster_name}"
  }
}

resource "azurerm_public_ip" "api_ip" {
  name                = "${var.cluster_name}_api_ip"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  allocation_method   = "Static"

  tags {
    GiantSwarmInstallation = "${var.cluster_name}"
  }
}

resource "azurerm_dns_a_record" "api_dns" {
  name                = "${var.api_dns}"
  zone_name           = "${var.base_domain}"
  resource_group_name = "${var.resource_group_name}"
  ttl                 = 300
  records             = ["${azurerm_public_ip.api_ip.ip_address}"]
}

resource "azurerm_lb_backend_address_pool" "api-lb" {
  name                = "api-lb-pool"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.api_lb.id}"
}

resource "azurerm_lb_rule" "api_lb" {
  name                    = "api-lb-rule-443-443"
  resource_group_name     = "${var.resource_group_name}"
  loadbalancer_id         = "${azurerm_lb.api_lb.id}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.api-lb.id}"
  probe_id                = "${azurerm_lb_probe.api_lb.id}"

  protocol                       = "tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "api"
}

resource "azurerm_lb_probe" "api_lb" {
  name                = "api-lb-probe-443-up"
  loadbalancer_id     = "${azurerm_lb.api_lb.id}"
  resource_group_name = "${var.resource_group_name}"
  protocol            = "tcp"
  port                = 443
  interval_in_seconds = 5
  number_of_probes    = 2
}
