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

output "vault_subnet" {
  value = "${azurerm_subnet.vault_subnet.id}"
}

output "vault_subnet_name" {
  value = "${azurerm_subnet.vault_subnet.name}"
}

output "vault_cidr" {
  value = "${azurerm_subnet.vault_subnet.address_prefix}"
}

output "vault_nsg_name" {
  value = "${azurerm_network_security_group.vault.name}"
}

output "vault_network_interface_ids" {
  value = ["${azurerm_network_interface.vault.id}"]
}

output "vpn_subnet_id" {
  value = "${element(concat(azurerm_subnet.vpn_subnet.*.id, list("")), 0)}"
}

output "vpn_subnet_name" {
  value = "${element(concat(azurerm_subnet.vpn_subnet.*.name, list("")), 0)}"
}

output "vpn_subnet_cidr" {
  value = "${element(concat(azurerm_subnet.vpn_subnet.*.address_prefix, list("")), 0)}"
}

output "worker_subnet" {
  value = "${azurerm_subnet.worker_subnet.id}"
}

output "worker_subnet_name" {
  value = "${azurerm_subnet.worker_subnet.name}"
}

output "worker_cidr" {
  value = "${azurerm_subnet.worker_subnet.address_prefix}"
}

output "worker_nsg_name" {
  value = "${azurerm_network_security_group.worker.name}"
}

output "worker_network_interface_ids" {
  value = ["${azurerm_network_interface.worker.*.id}"]
}

output "master_network_interface_ids" {
  value = ["${azurerm_network_interface.master.*.id}"]
}

output "api_backend_address_pool_id" {
  value = "${azurerm_lb_backend_address_pool.api-lb.id}"
}

output "ingress_backend_address_pool_id" {
  value = "${azurerm_lb_backend_address_pool.ingress-lb.id}"
}

output "vault_backend_address_pool_id" {
  value = "${azurerm_lb_backend_address_pool.vault-lb.id}"
}
