locals {
  tags = merge(var.additional_tags, map(
    "Name", var.cluster_name,
    "GiantSwarmInstallation", var.cluster_name
  ))
}

variable "location" {
  type = string
}

variable "cluster_name" {
  type = string
}

resource "azurerm_resource_group" "cluster_rg" {
  location = var.location
  name     = var.cluster_name

  tags = local.tags
}

output "id" {
  value = azurerm_resource_group.cluster_rg.id
}

output "name" {
  value = azurerm_resource_group.cluster_rg.name
}
