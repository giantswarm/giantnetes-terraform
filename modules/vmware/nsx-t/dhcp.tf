resource "nsxt_dhcp_server_profile" "server_profile" {
  edge_cluster_id = data.nsxt_policy_edge_cluster.edge_cluster.id
}

resource "nsxt_logical_dhcp_server" "dhcp_server" {
  display_name = format("dhcp-server-%s", var.cluster_name)

  dhcp_profile_id = nsxt_dhcp_server_profile.server_profile.id

  // reproduce tre behaviour of AWS setting the DHCP Server IP + 2 IP
  // i.e. CIDR: 10.100.0.0/8 - DHCP Server IP: 10.100.0.2
  dhcp_server_ip    = "${cidrhost(var.management_cluster_cidr, 2)}/${local.subnet_mask}"
  gateway_ip        = cidrhost(var.management_cluster_cidr, 1)
  dns_name_servers  = var.dns_addresses

  dynamic "tag" {
    for_each = var.tags

    content {
      scope = tag.value["scope"]
      tag   = tag.value["tag"]
    }
  }
}

resource "nsxt_logical_dhcp_port" "dhcp_port" {
  admin_state  = "UP"
  display_name = format("%s-%s-lp", nsxt_policy_segment.vmnet1.display_name, nsxt_logical_dhcp_server.dhcp_server.display_name)

  logical_switch_id = data.nsxt_policy_realization_info.segment_info.realized_id
  dhcp_server_id    = nsxt_logical_dhcp_server.dhcp_server.id

  dynamic "tag" {
    for_each = var.tags

    content {
      scope = tag.value["scope"]
      tag   = tag.value["tag"]
    }
  }
}

resource "nsxt_dhcp_server_ip_pool" "dhcp_ip_pool" {
  display_name           = format("ip-pool-%s-%s", nsxt_policy_segment.vmnet1.display_name, cidrhost(var.management_cluster_cidr, 0))
  logical_dhcp_server_id = nsxt_logical_dhcp_server.dhcp_server.id
  gateway_ip             = cidrhost(var.management_cluster_cidr, 1)
  lease_time             = 2592000
  error_threshold        = 98
  warning_threshold      = 70

  ip_range {
    // we start from 100 and leave the hosts unassigned
    start = cidrhost(var.management_cluster_cidr, 100)
    end   = cidrhost(var.management_cluster_cidr, local.max_hosts)
  }

  dynamic "tag" {
    for_each = var.tags

    content {
      scope = tag.value["scope"]
      tag   = tag.value["tag"]
    }
  }
}
