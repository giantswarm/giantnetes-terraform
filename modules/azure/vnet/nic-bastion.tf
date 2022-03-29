resource "azurerm_network_interface" "bastion" {
  count                = var.bastion_count
  name                 = "${var.cluster_name}-bastion-${count.index}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  enable_ip_forwarding = true

  ip_configuration {
    private_ip_address_allocation = "Dynamic"
    name                          = "${var.cluster_name}-bastionIPConfiguration"
    subnet_id                     = element(azurerm_subnet.bastion_subnet.*.id, count.index)
    public_ip_address_id          = var.vpn_enabled ? "" : element(concat(azurerm_public_ip.bastion_public_ip.*.id, list("")), count.index)
  }
}

resource "azurerm_public_ip" "bastion_public_ip" {
  count                   = var.vpn_enabled ? 0 : var.bastion_count
  name                    = "${var.cluster_name}-bastion-public-ip-${count.index}"
  location                = var.location
  resource_group_name     = var.resource_group_name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
}

resource "azurerm_dns_a_record" "bastion_dns" {
  count               = var.bastion_count
  name                = "bastion${count.index + 1}"
  zone_name           = var.base_domain
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [var.vpn_enabled ? element(azurerm_network_interface.bastion.*.private_ip_address, count.index) : element(concat(azurerm_public_ip.bastion_public_ip.*.ip_address, list("")), count.index)]
}
