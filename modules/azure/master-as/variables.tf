variable "container_linux_channel" {
  type = "string"
}

variable "container_linux_version" {
  type = "string"
}

variable "core_ssh_key" {
  description = "ssh key for user core"
  type        = "string"
}

variable "user_data" {
  type        = "string"
  description = "Generated user data"
}

variable "cluster_name" {
  type        = "string"
  description = "The name of the cluster."
}

variable "location" {
  type        = "string"
  description = "Location is the Azure Location (East US, West US, etc)"
}

variable "master_count" {
  type        = "string"
  description = "Count of master nodes to be created."
}

variable "network_interface_ids" {
  type        = "list"
  description = "List of NICs to use for Vault VMs"
}

variable "resource_group_name" {
  type = "string"
}

variable "storage_type" {
  type        = "string"
  description = "Storage account type"
}

variable "vm_size" {
  type        = "string"
  description = "VM Size name"
}

variable "docker_disk_size" {
  type        = "string"
  description = "Size of data disk in GB."
  default     = "100"
}

variable "etcd_disk_size" {
  type        = "string"
  description = "Size of data disk in GB."
  default     = "10"
}

variable "api_backend_address_pool_id" {
  type        = "string"
  description = "API load balances address pool id."
}

variable "boot_diagnostics_storage_uri" {
  type        = "string"
  description = "storage account uri fro boot diagnostics"
}
