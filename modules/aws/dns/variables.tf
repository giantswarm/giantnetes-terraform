variable "cluster_name" {
  type = string
}

variable "root_dns_zone_id" {
  type = string
}

variable "route53_enabled" {
  default = true
}

variable "vpc_id" {
  type = string
}

variable "zone_name" {
  type = string
}