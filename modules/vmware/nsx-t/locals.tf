locals {
  bastion_subnet_mask = split("/", var.bastion_subnet_cidr)[1]
  mc_subnet_mask      = split("/", var.management_cluster_cidr)[1]
  max_hosts           = pow(2, local.mc_subnet_mask) - 2
}
