variable "api_dns" {
  type = string
}

variable "arn_region" {
  type = string
}

variable "aws_account" {
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

variable "master_subnet_ids" {
  type = list
}

variable "user_data" {
  type = list(string)
}

variable "volume_type" {
  type    = string
  default = "gp2"
}

variable "private_dns_zone_id" {
  type = string
}


variable "public_dns_zone_id" {
  type = string
}

variable "k8s_api_whitelist" {
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
  default = 8
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

variable "route53_enabled" {
  default = true
}

variable "s3_bucket_tags" {}
