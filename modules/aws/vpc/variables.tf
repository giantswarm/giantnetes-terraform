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

variable "aws_cni_cidr_block" {
  type = string
}

variable "aws_cni_pod_cidrs" {
  type = list
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

### Access via transit VPC ###
variable "vpc_vgw_id" {
  description = "ID of the virtual private gateway, attached to VPC."
  default     = ""
  type = string
}

variable "transit_vpc_cidr" {
  description = "CIDR of the transit VPC, used to access installation bastions"
  default = ""
  type = string
}

