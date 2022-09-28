variable "cluster_name" {
  type = string
}

variable "location" {
  type        = string
  description = "Location is the Azure Location (East US, West US, etc)"
}

variable "subnet_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vpn_enabled" {
  type = string
}

variable "vpn_right_gateway_address_0" {
  type = string
}

variable "vpn_right_subnet_cidr_0" {
  type = string
}

variable "vpn_right_gateway_address_1" {
  type = string
}

variable "vpn_right_subnet_cidr_1" {
  type = string
}

variable "vpn_shared_key" {
  type = string
}

### additional tags
variable "additional_tags" {
  description = "Additional tags that can be added to all resources"
  type        = map
  default     = {}
}
