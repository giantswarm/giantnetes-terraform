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

variable "cloud_config_data" {
  type        = "string"
  description = "Generated cloud-config data"
}

variable "cluster_name" {
  type        = "string"
  description = "The name of the cluster."
}

variable "location" {
  type        = "string"
  description = "Location is the Azure Location (East US, West US, etc)"
}

variable "worker_count" {
  type        = "string"
  description = "Count of worker nodes to be created."
}

variable "resource_group_name" {
  type = "string"
}

variable "storage_type" {
  type        = "string"
  description = "Storage account type"
}

variable "subnet_id" {
  type        = "string"
  description = "ID of worker subnet"
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

variable "ingress_backend_address_pool_id" {
  type        = "string"
  description = "Ingress load balances address pool id."
}
