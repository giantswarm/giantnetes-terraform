resource "azurerm_lb" "vault_lb" {
  name                = "${var.cluster_name}-vault-lb"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  frontend_ip_configuration {
    name      = "vault"
    subnet_id = "${azurerm_subnet.vault_subnet.id}"
  }

  tags {
    GiantSwarmInstallation = "${var.cluster_name}"
  }
}

resource "azurerm_dns_a_record" "vault_dns" {
  name                = "${var.vault_dns}"
  zone_name           = "${var.base_domain}"
  resource_group_name = "${var.resource_group_name}"
  ttl                 = 300
  records             = ["${azurerm_lb.vault_lb.private_ip_address}"]
}

resource "azurerm_lb_backend_address_pool" "vault-lb" {
  name                = "vault-lb-pool"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.vault_lb.id}"
}

resource "azurerm_lb_rule" "vault_lb" {
  name                    = "${var.cluster_name}-vault-lb-rule-443-8200"
  resource_group_name     = "${var.resource_group_name}"
  loadbalancer_id         = "${azurerm_lb.vault_lb.id}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.vault-lb.id}"
  probe_id                = "${azurerm_lb_probe.vault_lb.id}"

  protocol                       = "tcp"
  frontend_port                  = 443
  backend_port                   = 8200
  frontend_ip_configuration_name = "vault"
}

resource "azurerm_lb_probe" "vault_lb" {
  name                = "${var.cluster_name}-vault-lb-probe-8200"
  loadbalancer_id     = "${azurerm_lb.vault_lb.id}"
  resource_group_name = "${var.resource_group_name}"
  protocol            = "tcp"
  port                = 8200
}
