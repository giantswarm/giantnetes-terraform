variable "iam_region" {
  type = "string"
}

variable "elb_subnet_ids" {
  type = "list"
}

variable "container_linux_ami_id" {
  type = "string"
}

variable "cluster_name" {
  type = "string"
}

variable "ignition_bucket_id" {
  type = "string"
}

variable "instance_type" {
  type = "string"
}

variable "user_data" {
  type = "string"
}

variable "volume_type" {
  type    = "string"
  default = "gp2"
}

variable "dns_zone_id" {
  type = "string"
}

variable "ipam_network_cidr" {
  description = "CIDR for guest VMs internal virtual network."
  type        = "string"
}

variable "volume_size_etcd" {
  type    = "string"
  default = 10
}

variable "volume_size_logs" {
  type    = "string"
  default = 5
}

variable "volume_size_root" {
  type    = "string"
  default = 8
}

variable "vault_count" {
  type    = "string"
  default = 1
}

variable "vault_dns" {
  type = "string"
}

variable "vault_port" {
  type    = "string"
  default = 8200
}

variable "vault_subnet_ids" {
  type = "list"
}

variable "vpc_cidr" {
  type = "string"
}

variable "vpc_id" {
  type = "string"
}

variable "worker_subnet_ids" {
  type = "list"
}

variable "route53_enabled" {
  default = false
}

variable "s3_bucket_tags" {}
