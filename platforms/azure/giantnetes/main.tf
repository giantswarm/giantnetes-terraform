provider "azurerm" {
  version = "=1.22.1"

  environment = "${var.azure_cloud}"
}

data "azurerm_client_config" "current" {}

module "container_linux" {
  source = "../../../modules/container-linux"

  coreos_channel = "${var.container_linux_channel}"
  coreos_version = "${var.container_linux_version}"
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
  base_domain         = "${var.base_domain}"
  bastion_count       = "2"
  bastion_cidr        = "${var.bastion_cidr}"
  cluster_name        = "${var.cluster_name}"
  etcd_dns            = "${var.etcd_dns}"
  ingress_dns         = "${var.ingress_dns}"
  location            = "${var.azure_location}"
  master_count        = "${var.master_count}"
  worker_count        = "${var.worker_count}"
  resource_group_name = "${module.resource_group.name}"
  vault_dns           = "${var.vault_dns}"
  vnet_cidr           = "${var.vnet_cidr}"
  vpn_enabled         = "${var.vpn_enabled}"
}

module "blob" {
  source = "../../../modules/azure/blob"

  cluster_name        = "${var.cluster_name}"
  azure_location      = "${var.azure_location}"
  resource_group_name = "${module.resource_group.name}"
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
    "BaseDomain"               = "${var.base_domain}"
    "BastionUsers"             = "${file("${path.module}/../../../ignition/bastion-users.yaml")}"
    "ClusterName"              = "${var.cluster_name}"
    "DockerCIDR"               = "${var.docker_cidr}"
    "DockerRegistry"           = "${var.docker_registry}"
    "ETCDDomainName"           = "${var.etcd_dns}.${var.base_domain}"
    "ETCDInitialClusterMulti"  = "etcd1=https://etcd1.${var.base_domain}:2380,etcd2=https://etcd2.${var.base_domain}:2380,etcd3=https://etcd3.${var.base_domain}:2380"
    "ETCDInitialClusterSingle" = "etcd1=https://etcd1.${var.base_domain}:2380"
    "G8SVaultToken"            = "${var.nodes_vault_token}"
    "K8SAPIIP"                 = "${var.k8s_api_ip}"
    "K8SDNSIP"                 = "${var.k8s_dns_ip}"
    "K8SServiceCIDR"           = "${var.k8s_service_cidr}"
    "MasterCount"              = "${var.master_count}"
    "MasterID"                 = "${var.master_id}"
    "PodCIDR"                  = "${var.pod_cidr}"
    "Provider"                 = "azure"
    "Users"                    = "${file("${path.module}/../../../ignition/users.yaml")}"
    "VaultDomainName"          = "${var.vault_dns}.${var.base_domain}"
  }
}

# Generate ignition config.
data "gotemplate" "bastion" {
  template = "${path.module}/../../../templates/bastion.yaml.tmpl"
  data     = "${jsonencode(local.ignition_data)}"
}

# Convert ignition config to raw json and merge users part.
data "ct_config" "bastion" {
  content      = "${data.gotemplate.bastion.rendered}"
  platform     = "azure"
  pretty_print = false
}

module "bastion" {
  source = "../../../modules/azure/bastion-as"

  bastion_count               = "2"
  cluster_name                = "${var.cluster_name}"
  core_ssh_key                = "${var.core_ssh_key}"
  container_linux_channel     = "${var.container_linux_channel}"
  container_linux_version     = "${module.container_linux.coreos_version}"
  location                    = "${var.azure_location}"
  network_interface_ids       = "${module.vnet.bastion_network_interface_ids}"
  platform_fault_domain_count = "${var.platform_fault_domain_count}"
  resource_group_name         = "${module.resource_group.name}"
  os_disk_storage_type        = "${var.os_disk_storage_type}"
  user_data                   = "${data.ct_config.bastion.rendered}"
  vm_size                     = "${var.bastion_vm_size}"
}

# Generate ignition config.
data "gotemplate" "vault" {
  template = "${path.module}/../../../templates/vault.yaml.tmpl"
  data     = "${jsonencode(local.ignition_data)}"
}

# Convert ignition config to raw json and merge users part.
data "ct_config" "vault" {
  content      = "${data.gotemplate.vault.rendered}"
  platform     = "azure"
  pretty_print = false
}

module "vault" {
  source = "../../../modules/azure/vault"

  cluster_name            = "${var.cluster_name}"
  container_linux_channel = "${var.container_linux_channel}"
  container_linux_version = "${module.container_linux.coreos_version}"
  core_ssh_key            = "${var.core_ssh_key}"
  location                = "${var.azure_location}"
  network_interface_ids   = "${module.vnet.vault_network_interface_ids}"
  os_disk_storage_type    = "${var.os_disk_storage_type}"
  resource_group_name     = "${module.resource_group.name}"
  storage_type            = "${var.vault_storage_type}"
  terraform_group_id      = "${var.terraform_group_id}"
  tenant_id               = "${data.azurerm_client_config.current.tenant_id}"
  user_data               = "${data.ct_config.vault.rendered}"
  vault_subnet            = "${module.vnet.vault_subnet}"
  vault_auto_unseal       = "${var.vault_auto_unseal}"
  vm_size                 = "${var.vault_vm_size}"
}

# Generate ignition config.
data "gotemplate" "master" {
  template = "${path.module}/../../../templates/master.yaml.tmpl"
  data     = "${jsonencode(local.ignition_data)}"
}

# Convert ignition config to raw json and merge users part.
data "ct_config" "master" {
  content      = "${data.gotemplate.master.rendered}"
  platform     = "azure"
  pretty_print = false
}

module "master" {
  source = "../../../modules/azure/master-as"

  api_backend_address_pool_id = "${module.vnet.api_backend_address_pool_id}"
  user_data                   = "${data.ct_config.master.rendered}"
  cluster_name                = "${var.cluster_name}"
  container_linux_channel     = "${var.container_linux_channel}"
  container_linux_version     = "${module.container_linux.coreos_version}"
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
  template = "${path.module}/../../../templates/worker.yaml.tmpl"
  data     = "${jsonencode(local.ignition_data)}"
}

# Convert ignition config to raw json and merge users part.
data "ct_config" "worker" {
  content      = "${data.gotemplate.worker.rendered}"
  platform     = "azure"
  pretty_print = false
}

module "worker" {
  source = "../../../modules/azure/worker-as"

  ingress_backend_address_pool_id = "${module.vnet.ingress_backend_address_pool_id}"
  user_data                       = "${data.ct_config.worker.rendered}"
  cluster_name                    = "${var.cluster_name}"
  container_linux_channel         = "${var.container_linux_channel}"
  container_linux_version         = "${module.container_linux.coreos_version}"
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

terraform = {
  required_version = ">= 0.11.0"

  backend "azurerm" {}
}
