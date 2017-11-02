module "container_linux" {
  source = "../../../modules/container-linux"

  channel = "${var.container_linux_channel}"
  version = "${var.container_linux_version}"
}

module "resource_group" {
  source = "../../../modules/azure/resource-group"

  location     = "${var.azure_location}"
  cluster_name = "${var.cluster_name}"
}

module "dns" {
  source = "../../../modules/azure/dns"

  location = "${var.azure_location}"

  cluster_name        = "${var.cluster_name}"
  resource_group_name = "${module.resource_group.name}"
  root_dns_zone_name  = "${var.root_dns_zone_name}"
  root_dns_zone_rg    = "${var.root_dns_zone_rg}"
  zone_name           = "${var.base_domain}"
}

module "vnet" {
  source = "../../../modules/azure/vnet"

  api_dns             = "${var.api_dns}"
  bastion_count       = "2"
  location            = "${var.azure_location}"
  cluster_name        = "${var.cluster_name}"
  ingress_dns         = "${var.ingress_dns}"
  resource_group_name = "${module.resource_group.name}"
  base_domain         = "${var.base_domain}"
  vault_dns           = "${var.vault_dns}"
  vnet_cidr           = "${var.vnet_cidr}"
}

data "template_file" "bastion_cloud_config" {
  template = "${file("${path.module}/../../../cloud-config/bastion.yaml.tmpl")}"
}

module "bastion" {
  source = "../../../modules/azure/bastion-as"

  bastion_count           = "2"
  cloud_config_data       = "${data.template_file.bastion_cloud_config.rendered}"
  cluster_name            = "${var.cluster_name}"
  container_linux_channel = "${var.container_linux_channel}"
  container_linux_version = "${module.container_linux.version}"
  location                = "${var.azure_location}"
  network_interface_ids   = "${module.vnet.bastion_network_interface_ids}"
  resource_group_name     = "${module.resource_group.name}"
  storage_type            = "${var.bastion_storage_type}"
  vm_size                 = "${var.bastion_vm_size}"
}

data "template_file" "vault_cloud_config" {
  template = "${file("${path.module}/../../../cloud-config/vault.yaml.tmpl")}"

  vars {
      "DOCKER_CIDR" = "${var.docker_cidr}"
  }
}

module "vault" {
  source = "../../../modules/azure/vault"

  cloud_config_data       = "${data.template_file.vault_cloud_config.rendered}"
  cluster_name            = "${var.cluster_name}"
  container_linux_channel = "${var.container_linux_channel}"
  container_linux_version = "${module.container_linux.version}"
  location                = "${var.azure_location}"
  network_interface_ids   = "${module.vnet.vault_network_interface_ids}"
  resource_group_name     = "${module.resource_group.name}"
  storage_type            = "${var.vault_storage_type}"
  vm_size                 = "${var.vault_vm_size}"
}
