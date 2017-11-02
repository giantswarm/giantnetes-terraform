resource "azurerm_lb" "cluster_lb" {
  name                = "${var.cluster_name}-cluster-lb"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  frontend_ip_configuration {
    name                          = "vault"
    public_ip_address_id          = "${azurerm_public_ip.vault_ip.id}"
    private_ip_address_allocation = "dynamic"
  }

  frontend_ip_configuration {
    name                          = "api"
    public_ip_address_id          = "${azurerm_public_ip.api_ip.id}"
    private_ip_address_allocation = "dynamic"
  }

  frontend_ip_configuration {
    name                          = "ingress"
    public_ip_address_id          = "${azurerm_public_ip.ingress_ip.id}"
    private_ip_address_allocation = "dynamic"
  }

  tags {
    Environment = "${var.cluster_name}"
  }
}
