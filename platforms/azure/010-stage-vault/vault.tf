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
