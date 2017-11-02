output "vnet_id" {
  value = "${azurerm_virtual_network.cluster_vnet.name}"
}

output "bastion_subnet" {
  value = "${azurerm_subnet.bastion_subnet.id}"
}

output "bastion_subnet_name" {
  value = "${azurerm_subnet.bastion_subnet.name}"
}

output "bastion_cidr" {
  value = "${azurerm_subnet.bastion_subnet.address_prefix}"
}

output "bastion_nsg_name" {
  value = "${azurerm_network_security_group.bastion.name}"
}

output "bastion_network_interface_ids" {
  value = ["${azurerm_network_interface.bastion.*.id}"]
}

output "vault_network_interface_ids" {
  value = ["${azurerm_network_interface.vault.id}"]
}
