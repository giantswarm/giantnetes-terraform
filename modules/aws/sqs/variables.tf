variable "cluster_name" {
  type = string
}

variable "aws_account" {
  type = string
}

variable "aws_region" {
  type = string
}

### additional tags
variable "additional_tags" {
  description = "Additional tags that can be added to all resources"
  type        = map(string)
  default     = {}
}
