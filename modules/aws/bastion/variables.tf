variable "aws_account" {
  type = "string"
}

variable "bastion_count" {
  type = "string"
}

variable "bastion_subnet_ids" {
  type = "list"
}

variable "container_linux_ami_id" {
  type = "string"
}

variable "cluster_name" {
  type = "string"
}

variable "instance_type" {
  type = "string"
}

variable "user_data" {
  type = "string"
}

variable "with_public_access" {
  type    = "string"
  default = ""
}

variable "volume_type" {
  type    = "string"
  default = "gp2"
}

variable "dns_zone_id" {
  type = "string"
}

variable "root_volume_size" {
  type    = "string"
  default = 30
}

variable "vpc_cidr" {
  type = "string"
}

variable "vpc_id" {
  type = "string"
}
