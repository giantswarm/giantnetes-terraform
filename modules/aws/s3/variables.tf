variable "aws_account" {
  type = "string"
}

variable "cluster_name" {
  type = "string"
}

variable "expiration_days" {
  type    = "string"
  default = "365"
}
