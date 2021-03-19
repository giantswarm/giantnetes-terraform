data "nsxt_policy_edge_cluster" "edge_cluster" {
  display_name = var.edge_cluster
}

data "nsxt_policy_tier0_gateway" "tier0_gw_gateway" {
  display_name = var.tier0_gateway
}

data "nsxt_policy_tier1_gateway" "tier1_gw_gateway" {
  count = var.tier1_gateway != "" ? 1 : 0

  display_name = var.tier1_gateway
}

data "nsxt_policy_transport_zone" "overlay" {
  display_name = var.transport_zone
}

data "nsxt_policy_realization_info" "segment_info" {
  path = nsxt_policy_segment.vmnet1.path
  entity_type = "RealizedLogicalSwitch"
}
