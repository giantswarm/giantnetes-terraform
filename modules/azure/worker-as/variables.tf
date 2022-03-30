variable "flatcar_linux_channel" {
  type = string
}

variable "flatcar_linux_version" {
  type = string
}

variable "core_ssh_key" {
  description = "ssh key for user core"
  type        = string
}

variable "delete_data_disks_on_termination" {
  default = false
}

variable "user_data" {
  type        = string
  description = "Generated user data"
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster."
}

variable "location" {
  type        = string
  description = "Location is the Azure Location (East US, West US, etc)"
}

variable "min_worker_count" {
  type        = string
  description = "Min number of worker nodes."
  default     = 3
}

variable "max_worker_count" {
  type        = string
  description = "Max number of worker nodes."
  default     = 6
}

variable "platform_fault_domain_count" {
  type        = string
  description = "Number of failure domains to use for availability set."
  default     = 3
}


variable "resource_group_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "enable_accelerated_networking" {
  type    = bool
  default = false
}

variable "os_disk_storage_type" {
  type        = string
  description = "Storage account type for OS disk."
}

variable "storage_type" {
  type        = string
  description = "Storage account type"
}

variable "vm_size" {
  type        = string
  description = "VM Size name"
}

variable "docker_disk_size" {
  type        = string
  description = "Size of data disk in GB."
  default     = "100"
}

variable "ingress_backend_address_pool_id" {
  type        = string
  description = "Ingress load balances address pool id."
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet to connect the workers to"
}

variable "node_health_probe_id" {
  type        = string
  description = "ID of the probe used to check nodes health"
}

variable "subscription_id" {
  type        = string
  description = "Subscription ID"
}

### additional tags
variable "additional_tags" {
  description = "Additional tags that can be added to all resources"
  type        = map
  default     = {}
}
