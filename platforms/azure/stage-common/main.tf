module "container_linux" {
  source = "../../../modules/container-linux"

  channel = "${var.container_linux_channel}"
  version = "${var.container_linux_version}"
}

module "resource_group" {
  source = "../../../modules/azure/resource-group"

  azure_location = "${var.azure_location}"
  cluster_name   = "${var.cluster_name}"
}

module "dns" {
  source = "../../../modules/azure/dns"

  azure_location      = "${var.azure_location}"
  cluster_name        = "${var.cluster_name}"
  resource_group_name = "${module.resource_group.name}"
  root_dns_zone_name  = "${var.root_dns_zone_name}"
  root_dns_zone_rg    = "${var.root_dns_zone_rg}"
  zone_name           = "${var.g8s_domain}"
}
