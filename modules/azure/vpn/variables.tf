variable "cluster_name" {
  type = "string"
}

variable "location" {
  type        = "string"
  description = "Location is the Azure Location (East US, West US, etc)"
}

variable "subnet_id" {
  type = "string"
}

variable "resource_group_name" {
  type = "string"
}

variable "vpn_enabled" {
  type = "string"
}

variable "vpn_right_gateway_address" {
  type = "string"
}

variable "vpn_right_subnet_cidr" {
  type = "string"
}
