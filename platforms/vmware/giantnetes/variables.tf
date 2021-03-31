# global cluster vars

variable "cluster_name" {
  type        = string
  description = "Cluster identifier which will be used in controller node names."
}

variable "provider_name" {
  type        = string
  description = "The name of the installation provider."
  default     = ""
}

variable "base_domain" {
  type        = string
  description = "Base domain for g8s cluster (e.g $CLUSTER_NAME.$PROVIDER.vmware.gigantic.io)."
}

# Route53 DNS variables

variable "root_dns_zone_id" {
  description = "Root DNS zone ID."
  default     = ""
}

# Required variables (NSX-T)
variable "nsxt_host" {
  type        = string
  description = "The host name or IP address of the NSX-T manager."
  default     = ""
}

variable "nsxt_username" {
  type        = string
  description = "The user name to connect to the NSX-T manager as."
  default     = ""
}

variable "nsxt_password" {
  type        = string
  description = "The password for the NSX-T manager user."
  default     = ""
}

variable "nsxt_enabled" {
  type        = bool
  description = "Whether to deploy NSX-T resources (NSX-T must be available in the customer's Data Center)."
  default     = false
}

variable "nsxt_edge_cluster" {
  type        = string
  description = "The Display Name prefix of the Edge Cluster to retrieve"
  default     = ""
}

variable "nsxt_tier0_gateway" {
  type        = string
  description = "NSX-T Tier 0 logical router."
  default     = ""
}

variable "nsxt_tier1_gateway" {
  type        = string
  description = "NSX-T Tier 1 logical router."
  default     = ""
}

variable "nsxt_transport_zone" {
  type        = string
  description = "NSX-T Transport zone."
  default     = ""
}

variable "management_cluster_cidr" {
  type        = string
  description = "Management Cluster CIDR block (i.e. 10.100.0.0/16)"
  default     = ""
}

variable "public_ip_address" {
  type        = string
  description = "Public IP address available in NSX-T"
  default     = ""
}

variable "dns_addresses" {
  type        = list(string)
  description = "Public IP address available in NSX-T"
  default = [
    "8.8.8.8",
    "8.8.4.4",
  ]
}

# Bastion variables

variable "bastion_host_count" {
  type        = number
  description = "Number of bastions to provision"
  default     = 1
}

variable "bastion_subnet_cidr" {
  type        = string
  description = "CIDR block to use for the bastion subnet"
  default     = ""
}

# Root DNS zone variables

variable "dns_use_route53" {
  type        = bool
  description = "Set whether Route53 should be used for the root DNS zone."
  default     = false
}

# Required variables (VSphere)

variable "vsphere_server" {
  type        = string
  description = "The host name or IP address of the VSphere client."
  default     = ""
}

variable "vsphere_user" {
  type        = string
  description = "The user name to connect to the VSphere client."
}

variable "vsphere_password" {
  type        = string
  description = "The password for the VSphere client."
}

variable "vsphere_datacenter" {
  type        = string
  description = "The name (ID) of the VMware datacenter. This can be a name or path."
}

variable "vsphere_datastore" {
  type        = string
  description = "The name (ID) of the VMware datastore. This can be a name or path."
}

variable "vsphere_compute_cluster" {
  type        = string
  description = "The name (ID) of the VMware computer cluster used for the placement of the virtual machine."
}

variable "vsphere_network" {
  type        = string
  description = "The name (ID) of the VMware network to connect the main interface to. This can be a name or path."
  default     = ""
}

variable "vsphere_template" {
  type        = string
  description = "The name (ID) of the VMware template used for the creation of the instance."
}

variable "vsphere_folder" {
  type        = string
  description = "The path to the folder to put this virtual machine in, relative to the datacenter that the resource pool is in."
}

# Optional variables.
variable "master_enabled" {
  type    = bool
  default = false
}

variable "master_node_count" {
  type        = number
  description = "Number of nodes to create."
  default     = 1
}

variable "master_cpus_count" {
  type        = number
  description = "The total number of virtual processor cores to assign to this virtual machine."
  default     = 4
}

variable "master_memory" {
  type        = number
  description = "The size of the virtual machine's memory, in MB."
  default     = 4096
}

variable "master_root_disk_size" {
  type        = number
  description = "The root size of the virtual machine's disk, in GB."
  default     = 30
}

variable "master_docker_disk_size" {
  type        = number
  description = "The root size of the virtual machine's disk, in GB."
  default     = 50
}

variable "master_etcd_disk_size" {
  type        = number
  description = "The root size of the virtual machine's disk, in GB."
  default     = 10
}

variable "nested_hv_enabled" {
  type        = bool
  description = "Enable nested hardware virtualization on this virtual machine, facilitating nested virtualization in the guest."
  default     = false
}

variable "tags" {
  type = list(object({
    scope = string
    tag   = string
  }))

  default = []
}

variable "worker_enabled" {
  type    = bool
  default = false
}

variable "worker_node_count" {
  type        = number
  description = "Number of nodes to create."
  default     = 1
}

variable "worker_cpus_count" {
  type        = number
  description = "The total number of virtual processor cores to assign to this virtual machine."
  default     = 4
}

variable "worker_memory" {
  type        = number
  description = "The size of the virtual machine's memory, in MB."
  default     = 4096
}

variable "worker_root_disk_size" {
  type        = number
  description = "The root size of the virtual machine's disk, in GB."
  default     = 30
}

variable "worker_docker_disk_size" {
  type        = number
  description = "The root size of the virtual machine's disk, in GB."
  default     = 50
}

variable "vault_enabled" {
  type    = bool
  default = false
}

variable "vault_cpus_count" {
  type        = number
  description = "The total number of virtual processor cores to assign to this virtual machine."
  default     = 4
}

variable "vault_memory" {
  type        = number
  description = "The size of the virtual machine's memory, in MB."
  default     = 4096
}

variable "vault_root_disk_size" {
  type        = number
  description = "The root size of the virtual machine's disk, in GB."
  default     = 30
}

variable "vault_etcd_disk_size" {
  type        = number
  description = "The root size of the virtual machine's disk, in GB."
  default     = 50
}


variable "vault_logs_disk_size" {
  type        = number
  description = "The root size of the virtual machine's disk, in GB."
  default     = 50
}

# Kubernetes
