variable "bastion_count" {
  type    = "string"
  default = "2"
}

variable "cluster_name" {
  type = "string"
}

variable "g8s_domain" {
  type = "string"
}

variable "resource_group_name" {
  type = "string"
}

variable "location" {
  type = "string"
}

variable "vnet_cidr" {
  type = "string"
}
