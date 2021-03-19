variable "cluster_name" {
  type        = string
  description = "Cluster identifier which will be used in controller node names."
}

variable "edge_cluster" {
  type        = string
  description = "NSX-T Edge Cluster"
}

variable "tier0_gateway" {
  type        = string
  description = "NSX-T Tier 0 router"
}

variable "tier1_gateway" {
  type        = string
  description = "NSX-T Tier 1 router"
  default     = ""
}

variable "transport_zone" {
  type        = string
  description = "NSX-T Transport Zone"
}

variable "management_cluster_cidr" {
  type        = string
  description = "CIDR block to assign to the Management Cluster VMs"
}

variable "public_ip_address" {
  type        = string
  description = "IP address used to translate private local IP address to public in the SNAT operation."
}

variable "dns_addresses" {
  type        = list(string)
  description = "DNS Nameserver IP addresses."
}


variable "tags" {
  type = list(object({
    scope = string
    tag   = string
  }))

  default = []
}
