variable "location" {
  type = "string"
}

variable "cluster_name" {
  type = "string"
}

variable "resource_group_name" {
  type = "string"
}

variable "root_dns_zone_name" {
  type = "string"
}

variable "root_dns_zone_rg" {
  type = "string"
}

variable "zone_name" {
  type = "string"
}

resource "azurerm_dns_zone" "dns_zone" {
  count               = "${var.root_dns_zone_name == "" ? 0 : 1}"
  name                = "${var.zone_name}"
  resource_group_name = "${var.resource_group_name}"

  tags = {
    Name                   = "${var.zone_name}"
    GiantSwarmInstallation = "${var.cluster_name}"
  }
}

resource "azurerm_dns_ns_record" "dns_zone_propagation" {
  count               = "${var.root_dns_zone_name == "" ? 0 : 1}"
  name                = "${var.cluster_name}.${var.location}"
  zone_name           = "${var.root_dns_zone_name}"
  resource_group_name = "${var.root_dns_zone_rg}"
  ttl                 = 300

  records = "${azurerm_dns_zone.dns_zone[count.index].name_servers}"

  tags = {
    GiantSwarmInstallation = "${var.cluster_name}"
  }
}
