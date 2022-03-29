resource "azurerm_network_interface" "vault" {
  name                = "${var.cluster_name}-vault"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    private_ip_address_allocation = "Dynamic"
    name                          = "${var.cluster_name}-vaultIPConfiguration"
    subnet_id                     = azurerm_subnet.vault_subnet.id
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "vault" {
  network_interface_id    = azurerm_network_interface.vault.id
  ip_configuration_name   = "${var.cluster_name}-vaultIPConfiguration"
  backend_address_pool_id = azurerm_lb_backend_address_pool.vault-lb.id
}

resource "azurerm_dns_a_record" "vault_private_dns" {
  name                = "vault1"
  zone_name           = var.base_domain
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_network_interface.vault.private_ip_address]
}
