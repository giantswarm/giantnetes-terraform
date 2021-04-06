terraform {
  backend "s3" {}
}

locals {
  tags = concat([{ scope = "Managed By Terraform", tag = "true" }], var.tags)
  ignition_data = {
    "Provider" = "vmware"
  }
}

provider "nsxt" {
  host     = var.nsxt_host
  username = var.nsxt_username
  password = var.nsxt_password
  # It is necessary in the case that NSX-T is deployed beheind a SSO (i.e. Workspaces ONE)
  remote_auth = true

  allow_unverified_ssl = true
}

module "nsxt" {
  source = "../../../modules/vmware/nsx-t"

  count = var.nsxt_enabled ? 1 : 0

  cluster_name            = var.cluster_name
  management_cluster_cidr = var.management_cluster_cidr

  edge_cluster   = var.nsxt_edge_cluster
  tier0_gateway  = var.nsxt_tier0_gateway
  tier1_gateway  = var.nsxt_tier1_gateway
  transport_zone = var.nsxt_transport_zone

  public_ip_address = var.public_ip_address
  dns_addresses     = var.dns_addresses

  bastion_host_count  = var.bastion_host_count
  bastion_subnet_cidr = var.bastion_subnet_cidr

  tags = local.tags
}

provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

module "vault" {
  source = "../../../modules/vmware/vault"

  count = var.vault_enabled ? 1 : 0

  cluster_name = var.cluster_name

  // VMware variables
  datacenter      = var.vsphere_datacenter
  datastore       = var.vsphere_datastore
  compute_cluster = var.vsphere_compute_cluster

  // In the case we do not use NSX-T the network where to attach VMs
  // must be already created and passed as input variable
  //
  network  = var.nsxt_enabled ? module.nsxt[0].vm_network : var.vsphere_network
  template = var.vsphere_template
  folder   = var.vsphere_folder

  cpus_count     = var.vault_cpus_count
  memory         = var.vault_memory
  root_disk_size = var.vault_root_disk_size
  etcd_disk_size = var.vault_etcd_disk_size
  logs_disk_size = var.vault_logs_disk_size

  ignition_data = ""

  tags = local.tags

  depends_on = [module.nsxt]
}

module "flatcar_linux" {
  source = "../../../modules/flatcar-linux"

  flatcar_channel = var.flatcar_linux_channel
  flatcar_version = var.flatcar_linux_version
}

data "http" "bastion_users" {
  url = "https://api.github.com/repos/giantswarm/employees/contents/employees.yaml?ref=${var.employees_branch}"

  request_headers = {
    Authorization = "token ${var.github_token}"
  }
}

# bastion ignition config
data "gotemplate" "bastion" {
  template    = "${path.module}/../../../templates/bastion.yaml.tmpl"
  data        = jsonencode(merge(local.ignition_data, { "NodeType" = "bastion" }))
  is_ignition = true
}

module "bastion" {
  source = "../../../modules/vmware/bastion"

  count = var.bastion_enabled ? 1 : 0

  cluster_name = var.cluster_name

  // VMware variables
  datacenter      = var.vsphere_datacenter
  datastore       = var.vsphere_datastore
  compute_cluster = var.vsphere_compute_cluster

  // In the case we do not use NSX-T the network where to attach VMs
  // must be already created and passed as input variable
  //
  network  = var.nsxt_enabled ? module.nsxt[0].bastion_network : var.vsphere_network
  template = var.vsphere_template
  folder   = var.vsphere_folder

  node_count       = var.bastion_node_count
  cpus_count       = var.bastion_cpus_count
  memory           = var.bastion_memory
  root_disk_size   = var.bastion_root_disk_size

  ignition_data = data.gotemplate.bastion.rendered

  tags = local.tags

  depends_on = [module.nsxt]
}

module "master" {
  source = "../../../modules/vmware/master"

  count = var.master_enabled ? 1 : 0

  cluster_name = var.cluster_name

  // VMware variables
  datacenter      = var.vsphere_datacenter
  datastore       = var.vsphere_datastore
  compute_cluster = var.vsphere_compute_cluster

  // In the case we do not use NSX-T the network where to attach VMs
  // must be already created and passed as input variable
  //
  network  = var.nsxt_enabled ? module.nsxt[0].vm_network : var.vsphere_network
  template = var.vsphere_template
  folder   = var.vsphere_folder

  node_count       = var.master_node_count
  cpus_count       = var.master_cpus_count
  memory           = var.master_memory
  root_disk_size   = var.master_root_disk_size
  docker_disk_size = var.master_docker_disk_size
  etcd_disk_size   = var.master_etcd_disk_size

  ignition_data = ""

  tags = local.tags

  depends_on = [module.nsxt]
}

module "worker" {
  source = "../../../modules/vmware/worker"

  count = var.worker_enabled ? 1 : 0

  cluster_name = var.cluster_name

  // VMware variables
  datacenter      = var.vsphere_datacenter
  datastore       = var.vsphere_datastore
  compute_cluster = var.vsphere_compute_cluster

  // In the case we do not use NSX-T the network where to attach VMs
  // must be already created and passed as input variable
  //
  network  = var.nsxt_enabled ? module.nsxt[0].vm_network : var.vsphere_network
  template = var.vsphere_template
  folder   = var.vsphere_folder

  node_count       = var.worker_node_count
  cpus_count       = var.worker_cpus_count
  memory           = var.worker_memory
  root_disk_size   = var.worker_root_disk_size
  docker_disk_size = var.worker_docker_disk_size

  ignition_data = ""

  tags = local.tags

  depends_on = [module.nsxt]
}

module "dns" {
  source = "../../../modules/aws/dns"

  count = var.dns_use_route53 ? 1 : 0

  cluster_name     = var.cluster_name
  root_dns_zone_id = var.root_dns_zone_id
  zone_name        = var.base_domain
}
