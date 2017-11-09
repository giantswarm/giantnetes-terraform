module "worker" {
  source = "../../../modules/azure/worker-ss"

  ingress_backend_address_pool_id = "${module.vnet.ingress_backend_address_pool_id}"
  cloud_config_data               = "${file("${path.cwd}/generated/master.sh")}"
  cluster_name                    = "${var.cluster_name}"
  container_linux_channel         = "${var.container_linux_channel}"
  container_linux_version         = "${module.container_linux.version}"
  core_ssh_key                    = "${var.core_ssh_key}"
  docker_disk_size                = "100"
  location                        = "${var.azure_location}"

  # Only single worker supported.
  worker_count        = "4"
  resource_group_name = "${module.resource_group.name}"
  storage_type        = "${var.worker_storage_type}"

  subnet_id = "${module.vnet.worker_subnet}"
  vm_size   = "${var.worker_vm_size}"
}
