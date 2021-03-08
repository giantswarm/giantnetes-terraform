locals {
  subnet_mask = split("/", var.management_cluster_cidr)[1]
  max_hosts   = pow(2, local.subnet_mask) - 2
}
