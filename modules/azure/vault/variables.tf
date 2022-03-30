variable "flatcar_linux_channel" {
  type = string
}

variable "flatcar_linux_version" {
  type = string
}

variable "image_publisher" {
  type    = string
  default = "kinvolk"
}

variable "image_offer" {
  type    = string
  default = "flatcar-container-linux-free"
}

variable "core_ssh_key" {
  description = "ssh key for user core"
  type        = string
}

variable "user_data" {
  type        = string
  description = "Generated user data"
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster."
}

variable "data_disk_size" {
  type        = string
  description = "Size of data disk in GB."
  default     = "10"
}

variable "logs_disk_size" {
  type        = string
  description = "Size of logs disk in GB."
  default     = "5"
}

variable "location" {
  type        = string
  description = "Location is the Azure Location (East US, West US, etc)"
}

variable "network_interface_ids" {
  type        = list(any)
  description = "List of NICs to use for Vault VMs"
}

variable "resource_group_name" {
  type = string
}

variable "os_disk_storage_type" {
  type        = string
  description = "Storage account type for OS disk."
}

variable "storage_type" {
  type        = string
  description = "Storage account type"
}

variable "subscription_id" {
  type        = string
  description = "Subscription ID"
}

variable "vm_size" {
  type        = string
  description = "VM Size name"
}

### additional tags
variable "additional_tags" {
  description = "Additional tags that can be added to all resources"
  type        = map
  default     = {}
}
