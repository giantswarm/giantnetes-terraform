module "master" {
  source = "../../../modules/azure/master-as"

  api_backend_address_pool_id = "${module.vnet.api_backend_address_pool_id}"
  cloud_config_data           = "${file("${path.cwd}/generated/master.sh")}"
  cluster_name                = "${var.cluster_name}"
  container_linux_channel     = "${var.container_linux_channel}"
  container_linux_version     = "${module.container_linux.version}"
  core_ssh_key                = "${var.core_ssh_key}"
  docker_disk_size            = "100"
  etcd_disk_size              = "10"
  location                    = "${var.azure_location}"

  # Only single master supported.
  master_count        = "1"
  resource_group_name = "${module.resource_group.name}"
  storage_type        = "${var.master_storage_type}"

  network_interface_ids = "${module.vnet.master_network_interface_ids}"
  vm_size               = "${var.master_vm_size}"
}
