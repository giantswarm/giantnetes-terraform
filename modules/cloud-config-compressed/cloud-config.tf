# This module is just workaround for custom_data size limit (e.g. 65Kb in Azure).
#
# 1) Render cloud-config from template
# 2) Compress, encode and write to script
# 3) Resulted script should be used as custom_data

variable "azure_cloud" {}
variable "azure_location" {}
variable "azure_sp_tenantid" {}
variable "azure_sp_subscriptionid" {}
variable "azure_sp_aadclientid" {}
variable "azure_sp_aadclientsecret" {}
variable "cluster_name" {}
variable "nodes_vault_token" {}
variable "base_domain" {}
variable "vault_dns" {}
variable "api_dns" {}
variable "etcd_dns" {}
variable "calico_cidr" {}
variable "docker_cidr" {}
variable "k8s_service_cidr" {}
variable "k8s_dns_ip" {}
variable "k8s_api_ip" {}
variable "target_dir" {}
variable "source_dir" {}

data "template_file" "master_cloud_config" {
  template = "${file("${var.source_dir}/master.yaml.tmpl")}"

  vars {
    "API_DOMAIN_NAME"   = "${var.api_dns}.${var.base_domain}"
    "AZURE_CLOUD" = "${var.azure_cloud}"
    "AZURE_LOCATION" = "${var.azure_location}"
    "AZURE_SP_TENANTID" = "${var.azure_sp_tenantid}"
    "AZURE_SP_SUBSCRIPTIONID" = "${var.azure_sp_subscriptionid}"
    "AZURE_SP_AADCLIENTID" = "${var.azure_sp_aadclientid}"
    "AZURE_SP_AADCLIENTSECRET" = "${var.azure_sp_aadclientsecret}"
    "AZURE_RESOURCEGROUP" = "${var.cluster_name}"
    "AZURE_SUBNETNAME" = "${var.cluster_name}_worker_subnet"
    "AZURE_SECGROUPNAME" = "${var.cluster_name}-worker"
    "AZURE_VNETNAME" = "${var.cluster_name}"
    "CALICO_CIDR"       = "${var.calico_cidr}"
    "ETCD_DOMAIN_NAME"  = "${var.etcd_dns}.${var.base_domain}"
    "G8S_VAULT_TOKEN"   = "${var.nodes_vault_token}"
    "DEFAULT_IPV4"      = "$${DEFAULT_IPV4}"
    "DOCKER_CIDR"       = "${var.docker_cidr}"
    "K8S_SERVICE_CIDR"  = "${var.k8s_service_cidr}"
    "K8S_DNS_IP"        = "${var.k8s_dns_ip}"
    "K8S_API_IP"        = "${var.k8s_api_ip}"
    "VAULT_DOMAIN_NAME" = "${var.vault_dns}.${var.base_domain}"
  }
}

resource "local_file" "master" {
  content  = "${data.template_file.master_cloud_config.rendered}"
  filename = "${var.target_dir}/master.yaml"

  # Compress, encode and put into script that will be provided as custom_data.
  provisioner "local-exec" {
    command = <<CMD
cp ${var.source_dir}/cloud-config.sh.tmlp ${var.target_dir}/master.sh;
DATA=$(cat ${var.target_dir}/master.yaml | gzip -9 | base64 -w 0)
sed -i "s,__DATA__,$${DATA}," ${var.target_dir}/master.sh
CMD
  }
}

data "template_file" "worker_cloud_config" {
  template = "${file("${var.source_dir}/worker.yaml.tmpl")}"

  vars {
    "API_DOMAIN_NAME"   = "${var.api_dns}.${var.base_domain}"
    "AZURE_CLOUD" = "${var.azure_cloud}"
    "AZURE_LOCATION" = "${var.azure_location}"
    "AZURE_SP_TENANTID" = "${var.azure_sp_tenantid}"
    "AZURE_SP_SUBSCRIPTIONID" = "${var.azure_sp_subscriptionid}"
    "AZURE_SP_AADCLIENTID" = "${var.azure_sp_aadclientid}"
    "AZURE_SP_AADCLIENTSECRET" = "${var.azure_sp_aadclientsecret}"
    "AZURE_RESOURCEGROUP" = "${var.cluster_name}"
    "AZURE_SUBNETNAME" = "${var.cluster_name}_worker_subnet"
    "AZURE_SECGROUPNAME" = "${var.cluster_name}-worker"
    "AZURE_VNETNAME" = "${var.cluster_name}"
    "CALICO_CIDR"       = "${var.calico_cidr}"
    "CLUSTER_NAME"      = "${var.cluster_name}"
    "DEFAULT_IPV4"      = "$${DEFAULT_IPV4}"
    "DOCKER_CIDR"       = "${var.docker_cidr}"
    "ETCD_DOMAIN_NAME"  = "${var.etcd_dns}.${var.base_domain}"
    "G8S_VAULT_TOKEN"   = "${var.nodes_vault_token}"
    "K8S_DNS_IP"        = "${var.k8s_dns_ip}"
    "VAULT_DOMAIN_NAME" = "${var.vault_dns}.${var.base_domain}"
  }
}

resource "local_file" "worker" {
  content  = "${data.template_file.worker_cloud_config.rendered}"
  filename = "${var.target_dir}/worker.yaml"

  # Compress, encode and put into script that will be provided as custom_data.
  provisioner "local-exec" {
    command = <<CMD
cp ${var.source_dir}/cloud-config.sh.tmlp ${var.target_dir}/worker.sh;
DATA=$(cat ${var.target_dir}/worker.yaml | gzip -9 | base64 -w 0)
sed -i "s,__DATA__,$${DATA}," ${var.target_dir}/worker.sh
CMD
  }
}
