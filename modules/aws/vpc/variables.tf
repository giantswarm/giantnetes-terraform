variable "arn_region" {
  type = string
}

variable "aws_account" {
  type = string
}

variable "az_count" {
  type    = string
  default = "2"
}

variable "cluster_name" {
  type = string
}

variable "subnets_bastion" {
  type = list
}

variable "subnets_elb" {
  type = list
}

variable "subnets_vault" {
  type = list
}

variable "subnets_worker" {
  type = list
}

variable "vpc_cidr" {
  type = string
}

variable "with_public_access" {
  type    = bool
  default = false
}
