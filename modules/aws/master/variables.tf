variable "api_dns" {
  type = "string"
}

variable "aws_account" {
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

variable "master_count" {
  type    = "string"
  default = 1
}

variable "master_subnet_ids" {
  type = "list"
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

variable "volume_size_docker" {
  type    = "string"
  default = 50
}

variable "volume_size_etcd" {
  type    = "string"
  default = 10
}

variable "volume_size_root" {
  type    = "string"
  default = 8
}

variable "volume_device_name_etcd" {
  type = "string"
}

variable "vpc_cidr" {
  type = "string"
}

variable "vpc_id" {
  type = "string"
}
