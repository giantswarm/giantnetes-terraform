variable "resource_group_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "azure_location" {
  type = string
}

### additional tags
variable "additional_tags" {
  description = "Additional tags that can be added to all resources"
  type        = map
  default     = {}
}
