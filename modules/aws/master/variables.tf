variable "api_dns" {
  type = string
}

variable "api_internal_dns" {
  type = string
}

variable "arn_region" {
  type = string
}

variable "aws_account" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "aws_cni_cidr_block" {
  type = string
}

variable "elb_subnet_ids" {
  type = list
}

variable "container_linux_ami_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "customer_vpn_public_subnets" {
    type = string
}

variable "customer_vpn_private_subnets" {
    type = string
}

variable "external_ipsec_public_ip_0" {
    type = string
}

variable "external_ipsec_public_ip_1" {
    type = string
}

variable "ignition_bucket_id" {
  type = string
}

variable "iam_region" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "master_count" {
  type    = string
  default = 1
}

variable "master_eni_ips" {
  type = list
}

variable "master_subnet_ids" {
  type = list
}

variable "nat_gateway_public_ips" {
  type = list
}

variable "user_data" {
  type = list(string)
}

variable "volume_type" {
  type    = string
  default = "gp3"
}

variable "dns_zone_id" {
  type = string
}

variable "volume_size_docker" {
  type    = string
  default = 50
}

variable "volume_size_etcd" {
  type    = string
  default = 10
}

variable "volume_size_root" {
  type    = string
  default = 30
}

variable "volume_docker" {
  type = string
}

variable "volume_etcd" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "s3_bucket_tags" {}

variable "sqs_temination_queue_arn" {
  type = string
}

### additional tags
variable "additional_tags" {
  description = "Additional tags that can be added to all resources"
  type        = map(string)
  default     = {}
}
