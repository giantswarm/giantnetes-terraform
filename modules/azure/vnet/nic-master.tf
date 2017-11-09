resource "azurerm_network_interface" "master" {
  count               = "${var.master_count}"
  name                = "${var.cluster_name}-master-${count.index}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  ip_configuration {
    private_ip_address_allocation           = "dynamic"
    name                                    = "${var.cluster_name}-masterIPConfiguration"
    subnet_id                               = "${azurerm_subnet.worker_subnet.id}"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.api-lb.id}"]
  }
}

# TODO: If more than one master this should become load balancer.
resource "azurerm_dns_a_record" "etcd_dns" {
  count               = "${var.master_count}"
  name                = "${var.etcd_dns}"
  zone_name           = "${var.base_domain}"
  resource_group_name = "${var.resource_group_name}"
  ttl                 = 300
  records             = ["${element(azurerm_network_interface.master.*.private_ip_address, count.index)}"]
}
