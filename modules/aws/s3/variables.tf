variable "aws_account" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "logs_expiration_days" {
  type = string
}

variable "s3_bucket_prefix" {
  type = string
}

### additional tags
variable "additional_tags" {
  description = "Additional tags that can be added to all resources"
  type        = map
  default     = {}
}
