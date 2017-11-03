variable "container_linux_channel" {
  type = "string"
}

variable "container_linux_version" {
  type = "string"
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

variable "master_count" {
  type        = "string"
  description = "Count of master nodes to be created."
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
  description = "ID of master subnet"
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
