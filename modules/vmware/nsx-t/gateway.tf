resource "nsxt_policy_tier1_gateway" "tier1_gw" {
  count = var.tier1_gateway != "" ? 0 : 1

  display_name              = format("t1-gw-%s", var.cluster_name)

  edge_cluster_path         = data.nsxt_policy_edge_cluster.edge_cluster.path
  failover_mode             = "NON_PREEMPTIVE"
  default_rule_logging      = "true"
  enable_firewall           = "true"
  enable_standby_relocation = "false"
  tier0_path                = data.nsxt_policy_tier0_gateway.tier0_gw_gateway.path
  route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED", "TIER1_IPSEC_LOCAL_ENDPOINT", "TIER1_NAT"]
  pool_allocation           = "ROUTING"

  dynamic "tag" {
    for_each = var.tags

    content {
      scope = tag.value["scope"]
      tag   = tag.value["tag"]
    }
  }
}

// Create a SNAT rule.
//
// This rule allows to map local network IP addresses to public one
resource "nsxt_policy_nat_rule" "rule" {
  display_name         = format("snat_%s", nsxt_policy_segment.vmnet1.display_name)
  action               = "SNAT"
  source_networks      = [var.management_cluster_cidr]
  translated_networks  = [var.public_ip_address]
  gateway_path         = var.tier1_gateway != "" ? data.nsxt_policy_tier1_gateway.tier1_gw_gateway[0].path : nsxt_policy_tier1_gateway.tier1_gw[0].path
  logging              = false
  firewall_match       = "MATCH_INTERNAL_ADDRESS"

  dynamic "tag" {
    for_each = var.tags

    content {
      scope = tag.value["scope"]
      tag   = tag.value["tag"]
    }
  }
}
