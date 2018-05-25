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

variable "data_disk_size" {
  type        = "string"
  description = "Size of data disk in GB."
  default     = "10"
}

variable "location" {
  type        = "string"
  description = "Location is the Azure Location (East US, West US, etc)"
}

variable "network_interface_ids" {
  type        = "list"
  description = "List of NICs to use for Vault VMs"
}

variable "resource_group_name" {
  type = "string"
}

variable "os_disk_storage_type" {
  type        = "string"
  description = "Storage account type for OS disk."
}

variable "storage_type" {
  type        = "string"
  description = "Storage account type"
}

variable "vm_size" {
  type        = "string"
  description = "VM Size name"
}
