variable "location" {
  type = string
}

variable "cluster_name" {
  type = string
}

resource "azurerm_resource_group" "cluster_rg" {
  location = var.location
  name     = var.cluster_name

  tags = {
    Name                   = var.cluster_name
    GiantSwarmInstallation = var.cluster_name
  }
}

output "id" {
  value = azurerm_resource_group.cluster_rg.id
}

output "name" {
  value = azurerm_resource_group.cluster_rg.name
}
