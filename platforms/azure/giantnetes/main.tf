provider "azurerm" {
  features {
    virtual_machine_scale_set {
      roll_instances_when_required = false
    }
  }
  metadata_host              = var.metadata_host
  environment                = var.environment
  skip_provider_registration = true

  subscription_id = var.azure_sp_subscriptionid
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_sp_tenantid
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

  location        = var.azure_location
  cluster_name    = var.cluster_name
  additional_tags = var.additional_tags
}

module "dns" {
  source = "../../../modules/azure/dns"

  location = var.azure_location

  cluster_name        = var.cluster_name
  resource_group_name = module.resource_group.name
  root_dns_zone_name  = var.root_dns_zone_name
  root_dns_zone_rg    = var.root_dns_zone_rg
  zone_name           = var.base_domain

  additional_tags = var.additional_tags
}

locals {
  vm_types_supporting_accelerated_networking = [
    "Standard_B12ms", "Standard_B16ms", "Standard_B20ms",
    "Standard_D2_v2", "Standard_D3_v2", "Standard_D4_v2", "Standard_D5_v2", "Standard_D11_v2", "Standard_D12_v2", "Standard_D13_v2", "Standard_D14_v2",
    "Standard_D2_v2_Promo", "Standard_D3_v2_Promo", "Standard_D4_v2_Promo", "Standard_D5_v2_Promo", "Standard_D11_v2_Promo", "Standard_D12_v2_Promo", "Standard_D13_v2_Promo", "Standard_D14_v2_Promo",
    "Standard_F2", "Standard_F4", "Standard_F8", "Standard_F16",
    "Standard_DS2_v2", "Standard_DS3_v2", "Standard_DS4_v2", "Standard_DS5_v2", "Standard_DS11-1_v2", "Standard_DS11_v2", "Standard_DS12-1_v2", "Standard_DS12-2_v2", "Standard_DS12_v2", "Standard_DS13-2_v2", "Standard_DS13-4_v2", "Standard_DS13_v2", "Standard_DS14-4_v2", "Standard_DS14-8_v2", "Standard_DS14_v2",
    "Standard_DS2_v2_Promo", "Standard_DS3_v2_Promo", "Standard_DS4_v2_Promo", "Standard_DS5_v2_Promo", "Standard_DS11_v2_Promo", "Standard_DS12_v2_Promo", "Standard_DS13_v2_Promo", "Standard_DS14_v2_Promo",
    "Standard_F2s", "Standard_F4s", "Standard_F8s", "Standard_F16s",
    "Standard_D4_v3", "Standard_D8_v3", "Standard_D16_v3", "Standard_D32_v3", "Standard_D48_v3", "Standard_D64_v3",
    "Standard_D4s_v3", "Standard_D8s_v3", "Standard_D16s_v3", "Standard_D32s_v3", "Standard_D48s_v3", "Standard_D64s_v3",
    "Standard_E4_v3", "Standard_E8_v3", "Standard_E16_v3", "Standard_E20_v3", "Standard_E32_v3",
    "Standard_E4-2s_v3", "Standard_E4s_v3", "Standard_E8-2s_v3", "Standard_E8-4s_v3", "Standard_E8s_v3", "Standard_E16-4s_v3", "Standard_E16-8s_v3",
    "Standard_E16s_v3", "Standard_E20s_v3", "Standard_E32-8s_v3", "Standard_E32-16s_v3", "Standard_E32s_v3",
    "Standard_M8-2ms", "Standard_M8-4ms", "Standard_M8ms", "Standard_M16-4ms", "Standard_M16-8ms", "Standard_M16ms", "Standard_M32-8ms", "Standard_M32-16ms", "Standard_M32ls", "Standard_M32ms", "Standard_M32ts", "Standard_M64-16ms", "Standard_M64-32ms", "Standard_M64ls", "Standard_M64ms", "Standard_M64s", "Standard_M128-32ms", "Standard_M128-64ms", "Standard_M128ms", "Standard_M128s",
    "Standard_M64", "Standard_M64m", "Standard_M128", "Standard_M128m",
    "Standard_PB6s",
    "Standard_D15_v2", "Standard_DS15_v2",
    "Standard_E48_v3", "Standard_E64i_v3", "Standard_E64_v3", "Standard_E48s_v3", "Standard_E64-16s_v3", "Standard_E64-32s_v3", "Standard_E64is_v3", "Standard_E64s_v3", "Standard_E4_v4", "Standard_E8_v4", "Standard_E16_v4", "Standard_E20_v4", "Standard_E32_v4", "Standard_E48_v4", "Standard_E64_v4", "Standard_E4d_v4",
    "Standard_E8d_v4", "Standard_E16d_v4", "Standard_E20d_v4", "Standard_E32d_v4", "Standard_E48d_v4", "Standard_E64d_v4",
    "Standard_E4-2s_v4", "Standard_E4s_v4", "Standard_E8-2s_v4", "Standard_E8-4s_v4", "Standard_E8s_v4", "Standard_E16-4s_v4", "Standard_E16-8s_v4", "Standard_E16s_v4", "Standard_E20s_v4", "Standard_E32-8s_v4", "Standard_E32-16s_v4", "Standard_E32s_v4", "Standard_E48s_v4", "Standard_E64-16s_v4", "Standard_E64-32s_v4", "Standard_E64s_v4",
    "Standard_E4-2ds_v4", "Standard_E4ds_v4", "Standard_E8-2ds_v4", "Standard_E8-4ds_v4", "Standard_E8ds_v4", "Standard_E16-4ds_v4", "Standard_E16-8ds_v4", "Standard_E16ds_v4", "Standard_E20ds_v4", "Standard_E32-8ds_v4", "Standard_E32-16ds_v4", "Standard_E32ds_v4", "Standard_E48ds_v4", "Standard_E64-16ds_v4", "Standard_E64-32ds_v4", "Standard_E64ds_v4",
    "Standard_D4d_v4", "Standard_D8d_v4", "Standard_D16d_v4", "Standard_D32d_v4", "Standard_D48d_v4", "Standard_D64d_v4", "Standard_D4_v4", "Standard_D8_v4", "Standard_D16_v4", "Standard_D32_v4", "Standard_D48_v4", "Standard_D64_v4",
    "Standard_D4ds_v4", "Standard_D8ds_v4", "Standard_D16ds_v4", "Standard_D32ds_v4", "Standard_D48ds_v4", "Standard_D64ds_v4",
    "Standard_D4s_v4", "Standard_D8s_v4", "Standard_D16s_v4", "Standard_D32s_v4", "Standard_D48s_v4", "Standard_D64s_v4",
    "Standard_F4s_v2", "Standard_F8s_v2", "Standard_F16s_v2", "Standard_F32s_v2", "Standard_F48s_v2", "Standard_F64s_v2", "Standard_F72s_v2",
    "Standard_NV12s_v3", "Standard_NV24s_v3", "Standard_NV48s_v3",
    "Standard_L8s_v2", "Standard_L16s_v2", "Standard_L32s_v2", "Standard_L48s_v2", "Standard_L64s_v2", "Standard_L80s_v2",
    "Standard_DC8_v2", "Standard_DC2s_v2", "Standard_DC4s_v2", "Standard_M208ms_v2",
    "Standard_M208s_v2", "Standard_M416-208s_v2", "Standard_M416s_v2", "Standard_M416-208ms_v2", "Standard_M416ms_v2",
    "Standard_NV4as_v4", "Standard_NV8as_v4", "Standard_NV16as_v4", "Standard_NV32as_v4",
    "Standard_D4a_v4", "Standard_D8a_v4", "Standard_D16a_v4", "Standard_D32a_v4", "Standard_D48a_v4", "Standard_D64a_v4", "Standard_D96a_v4",
    "Standard_D4as_v4", "Standard_D8as_v4", "Standard_D16as_v4", "Standard_D32as_v4", "Standard_D48as_v4", "Standard_D64as_v4", "Standard_D96as_v4",
    "Standard_E4a_v4", "Standard_E8a_v4", "Standard_E16a_v4", "Standard_E20a_v4", "Standard_E32a_v4", "Standard_E48a_v4", "Standard_E64a_v4", "Standard_E96a_v4",
    "Standard_E4as_v4", "Standard_E8as_v4", "Standard_E16as_v4", "Standard_E20as_v4", "Standard_E32as_v4", "Standard_E48as_v4", "Standard_E64as_v4", "Standard_E96as_v4"
  ]
}

module "vnet" {
  source = "../../../modules/azure/vnet"

  api_dns                              = var.api_dns
  api_dns_internal                     = var.api_dns_internal
  base_domain                          = var.base_domain
  bastion_count                        = "2"
  bastion_cidr                         = var.bastion_cidr
  cluster_name                         = var.cluster_name
  customer_vpn_public_subnets          = var.customer_vpn_public_subnets
  external_ipsec_public_ip_0           = var.external_ipsec_public_ip_0
  external_ipsec_public_ip_1           = var.external_ipsec_public_ip_1
  ingress_dns                          = var.ingress_dns
  location                             = var.azure_location
  master_count                         = var.master_count
  master_enable_accelerated_networking = contains(local.vm_types_supporting_accelerated_networking, var.master_vm_size) ? true : false
  worker_count                         = var.worker_count
  worker_enable_accelerated_networking = contains(local.vm_types_supporting_accelerated_networking, var.worker_vm_size) ? true : false
  resource_group_name                  = module.resource_group.name
  vault_dns                            = var.vault_dns
  vnet_cidr                            = var.vnet_cidr
  vpn_enabled                          = var.vpn_enabled

  additional_tags = var.additional_tags
}

module "blob" {
  source = "../../../modules/azure/blob"

  cluster_name        = var.cluster_name
  azure_location      = var.azure_location
  resource_group_name = module.resource_group.name

  additional_tags = var.additional_tags
}

locals {
  ignition_data = {
    "AzureCloud"               = var.azure_cloud
    "AzureLocation"            = var.azure_location
    "AzureSPTenantID"          = var.azure_sp_tenantid
    "AzureSPSubscriptionID"    = var.azure_sp_subscriptionid
    "AzureSPAADClientID"       = var.azure_sp_aadclientid
    "AzureSPAADClientSecret"   = var.azure_sp_aadclientsecret
    "AzureResourceGroup"       = var.cluster_name
    "AzureSubnetName"          = "${var.cluster_name}_worker_subnet"
    "AzureSecGroupName"        = "${var.cluster_name}-worker"
    "AzureVnetName"            = var.cluster_name
    "AzureRoutable"            = "${var.cluster_name}_worker_rt"
    "APIDomainName"            = "${var.api_dns}.${var.base_domain}"
    "APIInternalDomainName"    = "${var.api_dns_internal}.${var.base_domain}"
    "BaseDomain"               = var.base_domain
    "CalicoMTU"                = var.calico_mtu
    "ClusterDomain"            = var.cluster_domain
    "ClusterName"              = var.cluster_name
    "DisableAPIFairness"       = var.disable_api_fairness
    "DockerCIDR"               = var.docker_cidr
    "DockerRegistry"           = var.docker_registry
    "ETCDInitialClusterMulti"  = "etcd1=https://etcd1.${var.base_domain}:2380,etcd2=https://etcd2.${var.base_domain}:2380,etcd3=https://etcd3.${var.base_domain}:2380"
    "ETCDInitialClusterSingle" = "etcd1=https://etcd1.${var.base_domain}:2380"
    "GSReleaseVersion"         = var.release_version
    "K8SAPIIP"                 = var.k8s_api_ip
    "K8SAuditWebhookPort"      = var.k8s_audit_webhook_port
    "K8SDNSIP"                 = var.k8s_dns_ip
    "K8SServiceCIDR"           = var.k8s_service_cidr
    "K8sVersion"               = var.hyperkube_version
    "LogentriesEnabled"        = var.logentries_enabled
    "LogentriesPrefix"         = var.logentries_prefix
    "LogentriesToken"          = var.logentries_token
    "MasterCount"              = var.master_count
    "OIDCIssuerURL"            = "https://${var.oidc_issuer_dns}.${var.base_domain}"
    "PodCIDR"                  = var.pod_cidr
    "Provider"                 = "azure"
    "Users"                    = yamldecode(base64decode(jsondecode(data.http.bastion_users.body).content))
    "VaultDomainName"          = "${var.vault_dns}.${var.base_domain}"
    "VnetCIDR"                 = var.vnet_cidr
  }
}

# Generate ignition config.
data "gotemplate" "bastion" {
  template    = "${path.module}/../../../templates/bastion.yaml.tmpl"
  data        = jsonencode(merge(local.ignition_data, { "NodeType" = "bastion" }))
  is_ignition = true
}

module "bastion" {
  source = "../../../modules/azure/bastion-as"

  bastion_count               = "2"
  cluster_name                = var.cluster_name
  core_ssh_key                = var.core_ssh_key
  flatcar_linux_channel       = var.flatcar_linux_channel
  flatcar_linux_version       = module.flatcar_linux.flatcar_version
  location                    = var.azure_location
  network_interface_ids       = module.vnet.bastion_network_interface_ids
  platform_fault_domain_count = var.platform_fault_domain_count
  resource_group_name         = module.resource_group.name
  os_disk_storage_type        = var.os_disk_storage_type
  user_data                   = data.gotemplate.bastion.rendered
  vm_size                     = var.bastion_vm_size

  additional_tags = var.additional_tags
}

# Generate ignition config.
data "gotemplate" "vault" {
  template    = "${path.module}/../../../templates/vault.yaml.tmpl"
  data        = jsonencode(merge(local.ignition_data, { "NodeType" = "vault" }))
  is_ignition = true
}

module "vault" {
  source = "../../../modules/azure/vault"

  cluster_name          = var.cluster_name
  flatcar_linux_channel = var.flatcar_linux_channel
  flatcar_linux_version = module.flatcar_linux.flatcar_version
  image_publisher       = var.vault_image_publisher
  image_offer           = var.vault_image_offer
  core_ssh_key          = var.core_ssh_key
  location              = var.azure_location
  network_interface_ids = module.vnet.vault_network_interface_ids
  os_disk_storage_type  = var.os_disk_storage_type
  resource_group_name   = module.resource_group.name
  storage_type          = var.vault_storage_type
  subscription_id       = var.azure_sp_subscriptionid
  user_data             = data.gotemplate.vault.rendered
  vm_size               = var.vault_vm_size

  additional_tags = var.additional_tags
}

# Generate ignition config.
data "gotemplate" "master" {
  template    = "${path.module}/../../../templates/master.yaml.tmpl"
  data        = jsonencode(merge(local.ignition_data, { "NodeType" = "master" }))
  is_ignition = true
}


module "master" {
  source = "../../../modules/azure/master-as"

  load_balancer_backend_address_pool_ids = [module.vnet.api_backend_address_pool_id, module.vnet.internal_api_backend_address_pool_id]
  user_data                   = data.gotemplate.master.rendered
  cluster_name                = var.cluster_name
  flatcar_linux_channel       = var.flatcar_linux_channel
  flatcar_linux_version       = module.flatcar_linux.flatcar_version
  core_ssh_key                = var.core_ssh_key
  docker_disk_size            = "100"
  etcd_disk_size              = "64"
  location                    = var.azure_location

  master_count                = var.master_count
  resource_group_id           = module.resource_group.id
  resource_group_name         = module.resource_group.name
  os_disk_storage_type        = var.os_disk_storage_type
  platform_fault_domain_count = var.platform_fault_domain_count
  storage_type                = var.master_storage_type

  # it is intended to use the worker subnet for the masters as well
  subnet_id                   = module.vnet.worker_subnet
  node_health_probe_id        = module.vnet.master_nodes_health_probe_id
  vm_size                     = var.master_vm_size

  storage_acc       = module.blob.storage_acc
  storage_acc_url   = module.blob.storage_acc_url
  storage_container = module.blob.storage_container

  subscription_id = var.azure_sp_subscriptionid
  additional_tags = var.additional_tags
}

# Generate ignition config.
data "gotemplate" "worker" {
  template    = "${path.module}/../../../templates/worker.yaml.tmpl"
  data        = jsonencode(merge(local.ignition_data, { "NodeType" = "worker" }))
  is_ignition = true
}

module "worker" {
  source = "../../../modules/azure/worker-as"

  ingress_backend_address_pool_id = module.vnet.ingress_backend_address_pool_id
  user_data                       = data.gotemplate.worker.rendered
  cluster_name                    = var.cluster_name
  flatcar_linux_channel           = var.flatcar_linux_channel
  flatcar_linux_version           = module.flatcar_linux.flatcar_version
  core_ssh_key                    = var.core_ssh_key
  docker_disk_size                = "100"
  location                        = var.azure_location
  enable_accelerated_networking   = contains(local.vm_types_supporting_accelerated_networking, var.worker_vm_size) ? true : false
  subnet_id                       = module.vnet.worker_subnet
  node_health_probe_id            = module.vnet.worker_nodes_health_probe_id

  min_worker_count            = var.worker_count
  max_worker_count            = var.worker_count * 2
  resource_group_id           = module.resource_group.id
  resource_group_name         = module.resource_group.name
  os_disk_storage_type        = var.os_disk_storage_type
  platform_fault_domain_count = var.platform_fault_domain_count
  storage_type                = var.worker_storage_type

  vm_size = var.worker_vm_size

  subscription_id = var.azure_sp_subscriptionid
  additional_tags = var.additional_tags
}

module "vpn" {
  source = "../../../modules/azure/vpn"

  cluster_name                = var.cluster_name
  location                    = var.azure_location
  resource_group_name         = module.resource_group.name
  subnet_id                   = module.vnet.vpn_subnet_id
  vpn_enabled                 = var.vpn_enabled
  vpn_right_gateway_address_0 = var.vpn_right_gateway_address_0
  vpn_right_subnet_cidr_0     = var.vpn_right_subnet_cidr_0
  vpn_right_gateway_address_1 = var.vpn_right_gateway_address_1
  vpn_right_subnet_cidr_1     = var.vpn_right_subnet_cidr_1
  additional_tags             = var.additional_tags
}

terraform {
  required_version = ">= 0.12.6"

  backend "azurerm" {}
}
