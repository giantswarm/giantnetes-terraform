resource "nsxt_logical_dhcp_server" "dhcp_server_bastion" {
  display_name = format("dhcp-server-%s-bastion", var.cluster_name)

  dhcp_profile_id = nsxt_dhcp_server_profile.server_profile.id

  // reproduce the behaviour of AWS DHCP Server IP + 2 IP
  // i.e. CIDR: 10.100.0.0/8 - DHCP Server IP: 10.100.0.2
  dhcp_server_ip   = "${cidrhost(var.bastion_subnet_cidr, 2)}/${local.bastion_subnet_mask}"
  gateway_ip       = cidrhost(var.bastion_subnet_cidr, 1)
  dns_name_servers = var.dns_addresses

  dynamic "tag" {
    for_each = var.tags

    content {
      scope = tag.value["scope"]
      tag   = tag.value["tag"]
    }
  }
}

resource "nsxt_logical_dhcp_port" "dhcp_port_bastion" {
  admin_state  = "UP"
  display_name = format("%s-%s-lp", nsxt_policy_segment.bastion-vmnet.display_name, nsxt_logical_dhcp_server.dhcp_server_bastion.display_name)

  logical_switch_id = data.nsxt_policy_realization_info.bastion_segment_info.realized_id
  dhcp_server_id    = nsxt_logical_dhcp_server.dhcp_server_bastion.id

  dynamic "tag" {
    for_each = var.tags

    content {
      scope = tag.value["scope"]
      tag   = tag.value["tag"]
    }
  }
}

resource "nsxt_dhcp_server_ip_pool" "dhcp_bastion_ip_pool" {
  display_name           = format("ip-pool-%s-%s", nsxt_policy_segment.bastion-vmnet.display_name, cidrhost(var.bastion_subnet_cidr, 0))
  logical_dhcp_server_id = nsxt_logical_dhcp_server.dhcp_server_bastion.id
  gateway_ip             = cidrhost(var.bastion_subnet_cidr, 1)
  lease_time             = 2592000
  error_threshold        = 98
  warning_threshold      = 70

  ip_range {
    // start from local value (usually .5) and only allocate enough IPs for the requested number of bastions
    start = cidrhost(var.management_cluster_cidr, local.bastion_dhcp_pool_start)
    end   = cidrhost(var.management_cluster_cidr, local.bastion_dhcp_pool_end)
  }

  dynamic "tag" {
    for_each = var.tags

    content {
      scope = tag.value["scope"]
      tag   = tag.value["tag"]
    }
  }
}
