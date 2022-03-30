# Route table used by Azure cloud provider to setup pod routes.
resource "azurerm_route_table" "worker_rt" {
  name                = "${var.cluster_name}_worker_rt"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(local.common_tags, map(
    "GiantSwarmInstallation", var.cluster_name
  ))
}
