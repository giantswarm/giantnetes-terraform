resource "azurerm_network_interface" "master" {
  count               = "${var.master_count}"
  name                = "${var.cluster_name}-master-${count.index}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  enable_ip_forwarding = true

  ip_configuration {
    private_ip_address_allocation = "dynamic"
    name                          = "${var.cluster_name}-masterIPConfiguration"
    subnet_id                     = "${azurerm_subnet.worker_subnet.id}"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "master" {
  count                   = "${var.master_count}"
  network_interface_id    = "${element(azurerm_network_interface.master.*.id,count.index)}"
  ip_configuration_name   = "${var.cluster_name}-masterIPConfiguration"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.api-lb.id}}"
}

resource "azurerm_dns_a_record" "master_dns" {
  count               = "${var.master_count}"
  name                = "master${count.index + 1}"
  zone_name           = "${var.base_domain}"
  resource_group_name = "${var.resource_group_name}"
  ttl                 = 300
  records             = ["${element(azurerm_network_interface.master.*.private_ip_address, count.index)}"]
}

# TODO: If more than one master this should become load balancer.
resource "azurerm_dns_a_record" "etcd_dns" {
  count               = "${var.master_count}"
  name                = "etcd${count.index+1}"
  zone_name           = "${var.base_domain}"
  resource_group_name = "${var.resource_group_name}"
  ttl                 = 300
  records             = ["${element(azurerm_network_interface.master.*.private_ip_address, count.index)}"]
}
