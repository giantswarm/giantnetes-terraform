resource "azurerm_network_interface" "worker" {
  count               = "${var.worker_count}"
  name                = "${var.cluster_name}-worker-${count.index}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  ip_configuration {
    private_ip_address_allocation           = "dynamic"
    name                                    = "${var.cluster_name}-workerIPConfiguration"
    subnet_id                               = "${azurerm_subnet.worker_subnet.id}"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.ingress-lb.id}"]
  }
}
