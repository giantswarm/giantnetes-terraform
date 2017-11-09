module "cloud-config" {
  source = "../../../modules/cloud-config-compressed"

  target_dir = "${path.cwd}/generated"
  source_dir = "${path.module}/../../../cloud-config"

  cluster_name      = "${var.cluster_name}"
  nodes_vault_token = "${var.nodes_vault_token}"
  base_domain       = "${var.base_domain}"
  vault_dns         = "${var.vault_dns}"
  api_dns           = "${var.api_dns}"
  etcd_dns          = "${var.etcd_dns}"
  calico_cidr       = "${var.calico_cidr}"
  docker_cidr       = "${var.docker_cidr}"
  k8s_service_cidr  = "${var.k8s_service_cidr}"
  k8s_dns_ip        = "${var.k8s_dns_ip}"
  k8s_api_ip        = "${var.k8s_api_ip}"
}
