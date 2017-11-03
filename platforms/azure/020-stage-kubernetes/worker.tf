data "template_file" "worker_cloud_config" {
  template = "${file("${path.module}/../../../cloud-config/bastion.yaml.tmpl")}"

  vars {
    "CLUSTER_NAME"      = "${var.cluster_name}"
    "ETCD_DOMAIN_NAME"  = "${var.etcd_dns}.${var.base_domain}"
    "API_DOMAIN_NAME"   = "${var.api_dns}.${var.base_domain}"
    "VAULT_DOMAIN_NAME" = "${var.vault_dns}.${var.base_domain}"
    "G8S_VAULT_TOKEN"   = "${var.nodes_vault_token}"
    "CALICO_CIDR"       = "${var.calico_cidr}"
    "DOCKER_CIDR"       = "${var.docker_cidr}"
    "K8S_DNS_IP"        = "${var.k8s_dns_ip}"
    "DEFAULT_IPV4"      = "$${DEFAULT_IPV4}"
  }
}

module "worker" {
  source = "../../../modules/azure/worker-ss"

  ingress_backend_address_pool_id = "${module.vnet.ingress_backend_address_pool_id}"
  cloud_config_data               = "${data.template_file.worker_cloud_config.rendered}"
  cluster_name                    = "${var.cluster_name}"
  container_linux_channel         = "${var.container_linux_channel}"
  container_linux_version         = "${module.container_linux.version}"
  docker_disk_size                = "100"
  location                        = "${var.azure_location}"

  # Only single worker supported.
  worker_count        = "4"
  resource_group_name = "${module.resource_group.name}"
  storage_type        = "${var.worker_storage_type}"

  subnet_id = "${module.vnet.worker_subnet}"
  vm_size   = "${var.worker_vm_size}"
}
