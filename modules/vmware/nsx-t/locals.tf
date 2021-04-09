locals {
  mc_subnet_mask = split("/", var.management_cluster_cidr)[1]
  max_hosts      = pow(2, local.mc_subnet_mask) - 2

  bastion_subnet_mask     = split("/", var.bastion_subnet_cidr)[1]
  bastion_dhcp_pool_start = 5
  bastion_dhcp_pool_end   = local.bastion_dhcp_pool_start + local.bastion_host_count
  bastion_host_count      = var.bastion_host_count
}
