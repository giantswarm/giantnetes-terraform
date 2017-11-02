resource "azurerm_network_interface" "vault" {
  name                 = "${var.cluster_name}-vault"
  location             = "${var.location}"
  resource_group_name  = "${var.resource_group_name}"
  enable_ip_forwarding = true

  ip_configuration {
    private_ip_address_allocation           = "dynamic"
    name                                    = "${var.cluster_name}-vaultIPConfiguration"
    subnet_id                               = "${azurerm_subnet.vault_subnet.id}"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.vault-lb.id}"]
  }
}
