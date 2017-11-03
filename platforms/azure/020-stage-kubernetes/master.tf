data "template_file" "master_cloud_config" {
  template = "${file("${path.module}/../../../cloud-config/bastion.yaml.tmpl")}"

  vars {
    "ETCD_DOMAIN_NAME"  = "${var.etcd_dns}.${var.base_domain}"
    "API_DOMAIN_NAME"   = "${var.api_dns}.${var.base_domain}"
    "VAULT_DOMAIN_NAME" = "${var.vault_dns}.${var.base_domain}"
    "G8S_VAULT_TOKEN"   = "${var.nodes_vault_token}"
    "CALICO_CIDR"       = "${var.calico_cidr}"
    "DOCKER_CIDR"       = "${var.docker_cidr}"
    "K8S_SERVICE_CIDR"  = "${var.k8s_service_cidr}"
    "K8S_DNS_IP"        = "${var.k8s_dns_ip}"
    "K8S_API_IP"        = "${var.k8s_api_ip}"
    "DEFAULT_IPV4"      = "$${DEFAULT_IPV4}"
  }
}

module "master" {
  source = "../../../modules/azure/master-ss"

  api_backend_address_pool_id = "${module.vnet.api_backend_address_pool_id}"
  cloud_config_data           = "${data.template_file.master_cloud_config.rendered}"
  cluster_name                = "${var.cluster_name}"
  container_linux_channel     = "${var.container_linux_channel}"
  container_linux_version     = "${module.container_linux.version}"
  docker_disk_size            = "100"
  etcd_disk_size              = "10"
  location                    = "${var.azure_location}"

  # Only single master supported.
  master_count        = "1"
  resource_group_name = "${module.resource_group.name}"
  storage_type        = "${var.master_storage_type}"

  # NOTE: using worker subnet here. No real necessity to create separate one.
  subnet_id = "${module.vnet.worker_subnet}"
  vm_size   = "${var.master_vm_size}"
}
