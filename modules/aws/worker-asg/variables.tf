variable "arn_region" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "aws_cni_cidr_block" {
  type = string
}

variable "ingress_dns" {
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

variable "worker_count" {
  type = string
}

variable "worker_subnet_ids" {
  type = list
}

variable "user_data" {
  type = string
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

variable "volume_docker" {
  type = string
}

variable "volume_size_etcd" {
  type    = string
  default = 10
}

variable "volume_size_root" {
  type    = string
  default = 30
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
  type        = map
  default     = {}
}
