provider "azurerm" {
  # versions 1.34.0 and 1.35.0 break e2e tests, please don't use them.
  version = "~> 1.33.0"

  environment = var.azure_cloud
}

data "azurerm_client_config" "current" {}

data "http" "bastion_users" {
  url = "https://api.github.com/repos/giantswarm/employees/contents/employees.yaml?ref=${var.employees_branch}"

  # Optional request headers
  request_headers = {
    Authorization = "token ${var.github_token}"
  }
}

module "flatcar_linux" {
  source = "../../../modules/flatcar-linux"

  flatcar_channel = var.flatcar_linux_channel
  flatcar_version = var.flatcar_linux_version
}

module "resource_group" {
  source = "../../../modules/azure/resource-group"

  location     = var.azure_location
  cluster_name = var.cluster_name
}

module "dns" {
  source = "../../../modules/azure/dns"

  location = "${var.azure_location}"

  cluster_name        = var.cluster_name
  resource_group_name = module.resource_group.name
  root_dns_zone_name  = var.root_dns_zone_name
  root_dns_zone_rg    = var.root_dns_zone_rg
  zone_name           = var.base_domain
}

module "vnet" {
  source = "../../../modules/azure/vnet"

  api_dns                     = var.api_dns
  api_dns_internal            = var.api_dns_internal
  base_domain                 = var.base_domain
  bastion_count               = "2"
  bastion_cidr                = var.bastion_cidr
  cluster_name                = var.cluster_name
  customer_vpn_public_subnets = var.customer_vpn_public_subnets
  external_ipsec_public_ip_0  = var.external_ipsec_public_ip_0
  external_ipsec_public_ip_1  = var.external_ipsec_public_ip_1
  ingress_dns                 = var.ingress_dns
  location                    = var.azure_location
  master_count                = var.master_count
  worker_count                = var.worker_count
  resource_group_name         = module.resource_group.name
  vault_dns                   = var.vault_dns
  vnet_cidr                   = var.vnet_cidr
  vpn_enabled                 = var.vpn_enabled
}

module "blob" {
  source = "../../../modules/azure/blob"

  cluster_name        = var.cluster_name
  azure_location      = var.azure_location
  resource_group_name = module.resource_group.name
}

locals {
  ignition_data = {
    "AzureCloud"               = "${var.azure_cloud}"
    "AzureLocation"            = "${var.azure_location}"
    "AzureSPTenantID"          = "${var.azure_sp_tenantid}"
    "AzureSPSubscriptionID"    = "${var.azure_sp_subscriptionid}"
    "AzureSPAADClientID"       = "${var.azure_sp_aadclientid}"
    "AzureSPAADClientSecret"   = "${var.azure_sp_aadclientsecret}"
    "AzureResourceGroup"       = "${var.cluster_name}"
    "AzureSubnetName"          = "${var.cluster_name}_worker_subnet"
    "AzureSecGroupName"        = "${var.cluster_name}-worker"
    "AzureVnetName"            = "${var.cluster_name}"
    "AzureRoutable"            = "${var.cluster_name}_worker_rt"
    "APIDomainName"            = "${var.api_dns}.${var.base_domain}"
    "APIInternalDomainName"    = "${var.api_dns_internal}.${var.base_domain}"
    "BaseDomain"               = "${var.base_domain}"
    "CalicoMTU"                = "${var.calico_mtu}"
    "ClusterName"              = "${var.cluster_name}"
    "DockerCIDR"               = "${var.docker_cidr}"
    "DockerRegistry"           = "${var.docker_registry}"
    "ETCDInitialClusterMulti"  = "etcd1=https://etcd1.${var.base_domain}:2380,etcd2=https://etcd2.${var.base_domain}:2380,etcd3=https://etcd3.${var.base_domain}:2380"
    "ETCDInitialClusterSingle" = "etcd1=https://etcd1.${var.base_domain}:2380"
    "GSReleaseVersion"         = "${var.release_version}"
    "G8SVaultToken"            = "${var.nodes_vault_token}"
    "K8SAPIIP"                 = "${var.k8s_api_ip}"
    "K8SAuditWebhookPort"      = "${var.k8s_audit_webhook_port}"
    "K8SDNSIP"                 = "${var.k8s_dns_ip}"
    "K8SServiceCIDR"           = "${var.k8s_service_cidr}"
    "K8sVersion"               = "${var.hyperkube_version}"
    "LogentriesEnabled"        = "${var.logentries_enabled}"
    "LogentriesPrefix"         = "${var.logentries_prefix}"
    "LogentriesToken"          = "${var.logentries_token}"
    "MasterCount"              = "${var.master_count}"
    "OIDCEnabled"              = "${var.oidc_enabled}"
    "PodCIDR"                  = "${var.pod_cidr}"
    "Provider"                 = "azure"
    "Users"                    = yamldecode(base64decode(jsondecode(data.http.bastion_users.body).content))
    "VaultDomainName"          = "${var.vault_dns}.${var.base_domain}"
  }
}

# Generate ignition config.
data "gotemplate" "bastion" {
  template    = "${path.module}/../../../templates/bastion.yaml.tmpl"
  data        = "${jsonencode(merge(local.ignition_data, { "NodeType" = "bastion" }))}"
  is_ignition = true
}

module "bastion" {
  source = "../../../modules/azure/bastion-as"

  bastion_count               = "2"
  cluster_name                = "${var.cluster_name}"
  core_ssh_key                = "${var.core_ssh_key}"
  flatcar_linux_channel       = "${var.flatcar_linux_channel}"
  flatcar_linux_version       = "${module.flatcar_linux.flatcar_version}"
  location                    = "${var.azure_location}"
  network_interface_ids       = "${module.vnet.bastion_network_interface_ids}"
  platform_fault_domain_count = "${var.platform_fault_domain_count}"
  resource_group_name         = "${module.resource_group.name}"
  os_disk_storage_type        = "${var.os_disk_storage_type}"
  user_data                   = "${data.gotemplate.bastion.rendered}"
  vm_size                     = "${var.bastion_vm_size}"
}

# Generate ignition config.
data "gotemplate" "vault" {
  template    = "${path.module}/../../../templates/vault.yaml.tmpl"
  data        = "${jsonencode(merge(local.ignition_data, { "NodeType" = "vault" }))}"
  is_ignition = true
}

module "vault" {
  source = "../../../modules/azure/vault"

  cluster_name          = "${var.cluster_name}"
  flatcar_linux_channel = "${var.flatcar_linux_channel}"
  flatcar_linux_version = "${module.flatcar_linux.flatcar_version}"
  image_publisher       = "${var.vault_image_publisher}"
  image_offer           = "${var.vault_image_offer}"
  core_ssh_key          = "${var.core_ssh_key}"
  location              = "${var.azure_location}"
  network_interface_ids = "${module.vnet.vault_network_interface_ids}"
  os_disk_storage_type  = "${var.os_disk_storage_type}"
  resource_group_name   = "${module.resource_group.name}"
  storage_type          = "${var.vault_storage_type}"
  user_data             = "${data.gotemplate.vault.rendered}"
  vm_size               = "${var.vault_vm_size}"
}

# Generate ignition config.
data "gotemplate" "master" {
  count = "${var.master_count}"

  template    = "${path.module}/../../../templates/master.yaml.tmpl"
  data        = "${jsonencode(merge(local.ignition_data, { "NodeType" = "master", "MasterID" = "${count.index + 1}", "ETCDDomainName" = "etcd${count.index + 1}.${var.base_domain}" }))}"
  is_ignition = true
}


module "master" {
  source = "../../../modules/azure/master-as"

  api_backend_address_pool_id = "${module.vnet.api_backend_address_pool_id}"
  user_data                   = "${data.gotemplate.master.*.rendered}"
  cluster_name                = "${var.cluster_name}"
  flatcar_linux_channel       = "${var.flatcar_linux_channel}"
  flatcar_linux_version       = "${module.flatcar_linux.flatcar_version}"
  core_ssh_key                = "${var.core_ssh_key}"
  docker_disk_size            = "100"
  etcd_disk_size              = "10"
  location                    = "${var.azure_location}"

  master_count                = "${var.master_count}"
  resource_group_name         = "${module.resource_group.name}"
  os_disk_storage_type        = "${var.os_disk_storage_type}"
  platform_fault_domain_count = "${var.platform_fault_domain_count}"
  storage_type                = "${var.master_storage_type}"

  network_interface_ids = "${module.vnet.master_network_interface_ids}"
  vm_size               = "${var.master_vm_size}"

  storage_acc       = "${module.blob.storage_acc}"
  storage_acc_url   = "${module.blob.storage_acc_url}"
  storage_container = "${module.blob.storage_container}"
}

# Generate ignition config.
data "gotemplate" "worker" {
  template    = "${path.module}/../../../templates/worker.yaml.tmpl"
  data        = "${jsonencode(merge(local.ignition_data, { "NodeType" = "worker" }))}"
  is_ignition = true
}

module "worker" {
  source = "../../../modules/azure/worker-as"

  ingress_backend_address_pool_id = "${module.vnet.ingress_backend_address_pool_id}"
  user_data                       = "${data.gotemplate.worker.rendered}"
  cluster_name                    = "${var.cluster_name}"
  flatcar_linux_channel           = "${var.flatcar_linux_channel}"
  flatcar_linux_version           = "${module.flatcar_linux.flatcar_version}"
  core_ssh_key                    = "${var.core_ssh_key}"
  docker_disk_size                = "100"
  location                        = "${var.azure_location}"

  worker_count                = "${var.worker_count}"
  resource_group_name         = "${module.resource_group.name}"
  os_disk_storage_type        = "${var.os_disk_storage_type}"
  platform_fault_domain_count = "${var.platform_fault_domain_count}"
  storage_type                = "${var.worker_storage_type}"

  network_interface_ids = "${module.vnet.worker_network_interface_ids}"
  vm_size               = "${var.worker_vm_size}"
}

module "vpn" {
  source = "../../../modules/azure/vpn"

  cluster_name                = "${var.cluster_name}"
  location                    = "${var.azure_location}"
  resource_group_name         = "${module.resource_group.name}"
  subnet_id                   = "${module.vnet.vpn_subnet_id}"
  vpn_enabled                 = "${var.vpn_enabled}"
  vpn_right_gateway_address_0 = "${var.vpn_right_gateway_address_0}"
  vpn_right_subnet_cidr_0     = "${var.vpn_right_subnet_cidr_0}"
  vpn_right_gateway_address_1 = "${var.vpn_right_gateway_address_1}"
  vpn_right_subnet_cidr_1     = "${var.vpn_right_subnet_cidr_1}"
}

terraform {
  required_version = ">= 0.12.6"

  backend "azurerm" {}
}
