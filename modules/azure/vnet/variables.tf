variable "api_dns" {
  type    = "string"
  default = "api"
}

variable "bastion_count" {
  type = "string"
}

variable "base_domain" {
  type = "string"
}

variable "cluster_name" {
  type = "string"
}

variable "ingress_dns" {
  type    = "string"
  default = "ingress.g8s"
}

variable "resource_group_name" {
  type = "string"
}

variable "location" {
  type = "string"
}

variable "master_count" {
  type = "string"
}

variable "vault_dns" {
  type    = "string"
  default = "vault"
}

variable "vnet_cidr" {
  type = "string"
}
