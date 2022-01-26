variable "cluster_name" {
  type = string
}

variable "dns_zone_id" {
  type = string
}

variable "elb_subnet_ids" {
  type = list
}

variable "ingress_dns" {
  type = string
}

variable "vpc_id" {
  type = string
}

### additional tags
variable "additional_tags" {
  description = "Additional tags that can be added to all resources"
  type        = map
  default     = {}
}
