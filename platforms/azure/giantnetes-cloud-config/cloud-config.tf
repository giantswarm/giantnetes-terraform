# Module will create scripts with compressed cloud-config.
module "cloud-config" {
  source = "../../../modules/cloud-config-compressed"

  target_dir = "${path.cwd}/generated"
  source_dir = "${path.module}/../../../cloud-config"

  api_dns           = "${var.api_dns}"
  azure_cloud          = "${var.azure_cloud}"
  azure_location          = "${var.azure_location}"
  azure_sp_tenantid = "${var.azure_sp_tenantid}"
  azure_sp_subscriptionid = "${var.azure_sp_subscriptionid}"
  azure_sp_aadclientid = "${var.azure_sp_aadclientid}"
  azure_sp_aadclientsecret = "${var.azure_sp_aadclientsecret}"
  base_domain       = "${var.base_domain}"
  calico_cidr       = "${var.calico_cidr}"
  cluster_name      = "${var.cluster_name}"
  docker_cidr       = "${var.docker_cidr}"
  etcd_dns          = "${var.etcd_dns}"
  k8s_service_cidr  = "${var.k8s_service_cidr}"
  k8s_dns_ip        = "${var.k8s_dns_ip}"
  k8s_api_ip        = "${var.k8s_api_ip}"
  nodes_vault_token = "${var.nodes_vault_token}"
  vault_dns         = "${var.vault_dns}"
}
