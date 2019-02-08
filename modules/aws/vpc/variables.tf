variable "arn_region" {
  type = "string"
}

variable "aws_account" {
  type = "string"
}

variable "az_count" {
  type    = "string"
  default = "2"
}

variable "cluster_name" {
  type = "string"
}

variable "subnet_bastion" {
  type = "list"
}

variable "subnet_elb" {
  type = "list"
}

variable "subnet_vault" {
  type = "string"
}

variable "subnet_worker" {
  type = "list"
}

variable "vpc_cidr" {
  type = "string"
}

variable "with_public_access" {
  type    = "string"
  default = ""
}
