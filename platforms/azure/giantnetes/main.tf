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
  cluster_name        = "${var.cluster_name}"
  etcd_dns            = "${var.etcd_dns}"
  ingress_dns         = "${var.ingress_dns}"
  location            = "${var.azure_location}"
  master_count        = "1"
  worker_count        = "${var.worker_count}"
  resource_group_name = "${module.resource_group.name}"
  vault_dns           = "${var.vault_dns}"
  vnet_cidr           = "${var.vnet_cidr}"
}

locals {
  ignition_users = "${file("${path.module}/../../../ignition/users.yaml")}"
}

# Generate ignition config for bastions.
data "template_file" "bastion" {
  template = "${file("${path.module}/../../../ignition/bastion.yaml.tmpl")}"
}

# Convert ignition config to raw json and merge users part.
data "ct_config" "bastion" {
  content      = "${format("%s\n%s", local.ignition_users, data.template_file.bastion.rendered)}"
  platform     = "azure"
  pretty_print = false
}

module "bastion" {
  source = "../../../modules/azure/bastion-as"

  bastion_count           = "2"
  cluster_name            = "${var.cluster_name}"
  core_ssh_key            = "${var.core_ssh_key}"
  container_linux_channel = "${var.container_linux_channel}"
  container_linux_version = "${module.container_linux.coreos_version}"
  location                = "${var.azure_location}"
  network_interface_ids   = "${module.vnet.bastion_network_interface_ids}"
  resource_group_name     = "${module.resource_group.name}"
  storage_type            = "${var.bastion_storage_type}"
  user_data               = "${data.ct_config.bastion.rendered}"
  vm_size                 = "${var.bastion_vm_size}"
}

# Generate ignition config for Vault.
data "template_file" "vault" {
  template = "${file("${path.module}/../../../ignition/azure/vault.yaml.tmpl")}"

  vars {
    "DOCKER_CIDR" = "${var.docker_cidr}"
  }
}

# Convert ignition config to raw json and merge users part.
data "ct_config" "vault" {
  content      = "${format("%s\n%s", local.ignition_users, data.template_file.vault.rendered)}"
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
  resource_group_name     = "${module.resource_group.name}"
  storage_type            = "${var.vault_storage_type}"
  user_data               = "${data.ct_config.vault.rendered}"
  vm_size                 = "${var.vault_vm_size}"
}

# Generate ignition config for master.
data "template_file" "master_big" {
  template = "${file("${path.module}/../../../ignition/azure/master.yaml.tmpl")}"

  vars {
    "API_DOMAIN_NAME"          = "${var.api_dns}.${var.base_domain}"
    "AZURE_CLOUD"              = "${var.azure_cloud}"
    "AZURE_LOCATION"           = "${var.azure_location}"
    "AZURE_SP_TENANTID"        = "${var.azure_sp_tenantid}"
    "AZURE_SP_SUBSCRIPTIONID"  = "${var.azure_sp_subscriptionid}"
    "AZURE_SP_AADCLIENTID"     = "${var.azure_sp_aadclientid}"
    "AZURE_SP_AADCLIENTSECRET" = "${var.azure_sp_aadclientsecret}"
    "AZURE_RESOURCEGROUP"      = "${var.cluster_name}"
    "AZURE_SUBNETNAME"         = "${var.cluster_name}_worker_subnet"
    "AZURE_SECGROUPNAME"       = "${var.cluster_name}-worker"
    "AZURE_VNETNAME"           = "${var.cluster_name}"
    "AZURE_ROUTETABLE"         = "${var.cluster_name}_worker_rt"
    "POD_CIDR"                 = "${var.pod_cidr}"
    "K8S_SERVICE_CIDR"         = "${var.k8s_service_cidr}"
    "K8S_API_IP"               = "${var.k8s_api_ip}"
    "CLUSTER_NAME"             = "${var.cluster_name}"
    "DEFAULT_IPV4"             = "$${DEFAULT_IPV4}"
    "DOCKER_CIDR"              = "${var.docker_cidr}"
    "ETCD_DOMAIN_NAME"         = "${var.etcd_dns}.${var.base_domain}"
    "G8S_VAULT_TOKEN"          = "${var.nodes_vault_token}"
    "K8S_DNS_IP"               = "${var.k8s_dns_ip}"
    "VAULT_DOMAIN_NAME"        = "${var.vault_dns}.${var.base_domain}"
  }
}

# Convert ignition config to raw json and merge users part.
data "ct_config" "master_big" {
  content      = "${format("%s\n%s", local.ignition_users, data.template_file.master_big.rendered)}"
  platform     = "azure"
  pretty_print = false
}

resource "local_file" "master_ignition_big" {
  content  = "${data.ct_config.master_big.rendered}"
  filename = "${path.cwd}/generated/master-ignition.yaml"
}

resource "azurerm_storage_account" "storage_acc" {
  name                     = "${var.cluster_name}machine"
  resource_group_name      = "${module.resource_group.name}"
  location                 = "westeurope"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "ignition" {
  name                  = "ignition"
  resource_group_name   = "${module.resource_group.name}"
  storage_account_name  = "${azurerm_storage_account.storage_acc.name}"
  container_access_type = "container"
}

resource "azurerm_storage_blob" "ignition_blob" {
  name = "master-ignition-${timestamp()}.yaml"

  resource_group_name    = "${module.resource_group.name}"
  storage_account_name   = "${azurerm_storage_account.storage_acc.name}"
  storage_container_name = "${azurerm_storage_container.ignition.name}"

  type   = "block"
  source = "${path.cwd}/generated/master-ignition.yaml"
}

data "ignition_config" "loader" {
  replace {
    source = "${azurerm_storage_blob.ignition_blob.url}"
  }
}

module "master" {
  source = "../../../modules/azure/master-as"

  api_backend_address_pool_id = "${module.vnet.api_backend_address_pool_id}"
  user_data                   = "${data.ignition_config.loader.rendered}"
  cluster_name                = "${var.cluster_name}"
  container_linux_channel     = "${var.container_linux_channel}"
  container_linux_version     = "${module.container_linux.coreos_version}"
  core_ssh_key                = "${var.core_ssh_key}"
  docker_disk_size            = "100"
  etcd_disk_size              = "10"
  location                    = "${var.azure_location}"

  # Only single master supported.
  master_count        = "1"
  resource_group_name = "${module.resource_group.name}"
  storage_type        = "${var.master_storage_type}"

  network_interface_ids        = "${module.vnet.master_network_interface_ids}"
  vm_size                      = "${var.master_vm_size}"
  boot_diagnostics_storage_uri = "${azurerm_storage_account.storage_acc.primary_blob_endpoint}"
}

# Generate ignition config for worker.
data "template_file" "worker" {
  template = "${file("${path.module}/../../../ignition/azure/worker.yaml.tmpl")}"

  vars {
    "API_DOMAIN_NAME"          = "${var.api_dns}.${var.base_domain}"
    "AZURE_CLOUD"              = "${var.azure_cloud}"
    "AZURE_LOCATION"           = "${var.azure_location}"
    "AZURE_SP_TENANTID"        = "${var.azure_sp_tenantid}"
    "AZURE_SP_SUBSCRIPTIONID"  = "${var.azure_sp_subscriptionid}"
    "AZURE_SP_AADCLIENTID"     = "${var.azure_sp_aadclientid}"
    "AZURE_SP_AADCLIENTSECRET" = "${var.azure_sp_aadclientsecret}"
    "AZURE_RESOURCEGROUP"      = "${var.cluster_name}"
    "AZURE_SUBNETNAME"         = "${var.cluster_name}_worker_subnet"
    "AZURE_SECGROUPNAME"       = "${var.cluster_name}-worker"
    "AZURE_VNETNAME"           = "${var.cluster_name}"
    "AZURE_ROUTETABLE"         = "${var.cluster_name}_worker_rt"
    "POD_CIDR"                 = "${var.pod_cidr}"
    "CLUSTER_NAME"             = "${var.cluster_name}"
    "DEFAULT_IPV4"             = "$${DEFAULT_IPV4}"
    "DOCKER_CIDR"              = "${var.docker_cidr}"
    "ETCD_DOMAIN_NAME"         = "${var.etcd_dns}.${var.base_domain}"
    "G8S_VAULT_TOKEN"          = "${var.nodes_vault_token}"
    "K8S_DNS_IP"               = "${var.k8s_dns_ip}"
    "VAULT_DOMAIN_NAME"        = "${var.vault_dns}.${var.base_domain}"
  }
}

# Convert ignition config to raw json and merge users part.
data "ct_config" "worker" {
  content      = "${format("%s\n%s", local.ignition_users, data.template_file.worker.rendered)}"
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

  worker_count        = "${var.worker_count}"
  resource_group_name = "${module.resource_group.name}"
  storage_type        = "${var.worker_storage_type}"

  network_interface_ids = "${module.vnet.worker_network_interface_ids}"
  vm_size               = "${var.worker_vm_size}"
}
