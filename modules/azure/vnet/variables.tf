variable "api_dns" {
  type    = string
  default = "api"
}

variable "bastion_count" {
  type = string
}

variable "bastion_cidr" {
  type = string
}

variable "base_domain" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "ingress_dns" {
  type    = string
  default = "ingress.g8s"
}

variable "k8s_api_whitelist" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "master_count" {
  type = string
}

variable "worker_count" {
  type = string
}

variable "vault_dns" {
  type    = string
  default = "vault"
}

variable "vnet_cidr" {
  type = string
}

variable "vpn_enabled" {
  type = string
}
