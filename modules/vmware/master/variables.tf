# Required variables.
variable "datacenter" {
  type        = string
  description = "The name (ID) of the VMware datacenter. This can be a name or path."
}

variable "datastore" {
  type        = string
  description = "The name (ID) of the VMware datastore. This can be a name or path."
}

variable "compute_cluster" {
  type        = string
  description = "The name (ID) of the VMware computer cluster used for the placement of the virtual machine."
}

variable "network" {
  type        = string
  description = "The name (ID) of the VMware network to connect the main interface to. This can be a name or path."
}

variable "template" {
  type        = string
  description = "The name (ID) of the VMware template used for the creation of the instance."
}

variable "folder" {
  type        = string
  description = "The path to the folder to put this virtual machine in, relative to the datacenter that the resource pool is in."
}

variable "cluster_name" {
  type        = string
  description = "Cluster identifier which will be used in controller node names."
}

variable "ignition_data" {
  type        = string
  description = "Ignition config template (non-base64)."
}

# Optional variables.
variable "node_count" {
  type        = number
  description = "Number of nodes to create."
  default     = 1
}

variable "cpus_count" {
  type        = number
  description = "The total number of virtual processor cores to assign to this virtual machine."
  default     = 4
}

variable "memory" {
  type        = number
  description = "The size of the virtual machine's memory, in MB."
  default     = 4096
}

variable "root_disk_size" {
  type        = number
  description = "The root size of the virtual machine's disk, in GB."
  default     = 30
}

variable "docker_disk_size" {
  type        = number
  description = "The root size of the virtual machine's disk, in GB."
  default     = 50
}

variable "etcd_disk_size" {
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
