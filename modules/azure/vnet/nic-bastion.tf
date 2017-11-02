resource "azurerm_network_interface" "bastion" {
  count                = "${var.bastion_count}"
  name                 = "${var.cluster_name}-bastion-${count.index}"
  location             = "${var.location}"
  resource_group_name  = "${var.resource_group_name}"
  enable_ip_forwarding = true

  ip_configuration {
    private_ip_address_allocation = "dynamic"
    name                          = "${var.cluster_name}-bastionIPConfiguration"
    subnet_id                     = "${element(azurerm_subnet.bastion_subnet.*.id, count.index)}"
    public_ip_address_id          = "${element(azurerm_public_ip.bastion_public_ip.*.id, count.index)}"
  }
}

resource "azurerm_public_ip" "bastion_public_ip" {
  count                        = "${var.bastion_count}"
  name                         = "${var.cluster_name}-bastion-public-ip-${count.index}"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "Static"
  idle_timeout_in_minutes      = 30
}

resource "azurerm_dns_a_record" "bastion_dns" {
  count               = "${var.bastion_count}"
  name                = "bastion-${count.index}"
  zone_name           = "${var.base_domain}"
  resource_group_name = "${var.resource_group_name}"
  ttl                 = 300
  records             = ["${element(azurerm_public_ip.bastion_public_ip.*.ip_address, count.index)}"]
}
