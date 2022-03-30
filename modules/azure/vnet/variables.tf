variable "api_dns" {
  type    = string
  default = "api"
}

variable "api_dns_internal" {
  type    = string
  default = "internal-api"
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

variable "customer_vpn_public_subnets" {
    type = string
}

variable "external_ipsec_public_ip_0" {
    type = string
}

variable "external_ipsec_public_ip_1" {
    type = string
}

variable "ingress_dns" {
  type    = string
  default = "ingress.g8s"
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

variable "master_enable_accelerated_networking" {
  type = bool
  default = false
}

variable "worker_count" {
  type = string
}

variable "worker_enable_accelerated_networking" {
  type = bool
  default = false
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

### additional tags
variable "additional_tags" {
  description = "Additional tags that can be added to all resources"
  type        = map
  default     = {}
}
