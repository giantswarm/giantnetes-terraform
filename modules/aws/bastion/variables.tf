variable "arn_region" {
  type = string
}

variable "aws_account" {
  type = string
}


variable "aws_cni_subnets" {
  type        = list
  description = "CIDR for AWS CNI networks used for pods."
}

variable "bastion_count" {
  type = string
}

variable "bastion_subnet_ids" {
  type = list
}

variable "container_linux_ami_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "external_ipsec_subnet" {
  type    = string
  default = "172.18.0.0/29"
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

variable "user_data" {
  type = string
}

variable "with_public_access" {
  type    = bool
  default = false
}

variable "volume_type" {
  type    = string
  default = "gp3"
}

variable "dns_zone_id" {
  type = string
}

variable "volume_size_root" {
  type    = string
  default = 8
}

variable "vpc_cidr" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "forward_logs_enabled" {
  default = true
}

variable "s3_bucket_tags" {}

### Access via transit VPC ###
variable "transit_vpc_cidr" {
  description = "CIDR of the transit VPC, used to access installation bastions"
  type        = string
}

### additional tags
variable "additional_tags" {
  description = "Additional tags that can be added to all resources"
  type        = map
  default     = {}
}

