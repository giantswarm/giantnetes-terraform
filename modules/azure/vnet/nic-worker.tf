resource "azurerm_network_interface" "worker" {
  count               = var.worker_count
  name                = "${var.cluster_name}-worker-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name

  enable_ip_forwarding = true

  ip_configuration {
    private_ip_address_allocation = "dynamic"
    name                          = "${var.cluster_name}-workerIPConfiguration"
    subnet_id                     = azurerm_subnet.worker_subnet.id
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "worker" {
  count                   = var.worker_count
  network_interface_id    = element(azurerm_network_interface.worker.*.id, count.index)
  ip_configuration_name   = "${var.cluster_name}-workerIPConfiguration"
  backend_address_pool_id = azurerm_lb_backend_address_pool.ingress-lb.id
}
