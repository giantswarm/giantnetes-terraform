resource "nsxt_policy_segment" "vmnet1" {
  display_name        = format("%s-vmnet1", var.cluster_name)
  connectivity_path   = var.tier1_gateway != "" ? data.nsxt_policy_tier1_gateway.tier1_gw_gateway[0].path : nsxt_policy_tier1_gateway.tier1_gw[0].path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay.path

  nsx_id = format("%s-vmnet1", var.cluster_name)

  subnet {
    cidr = "${cidrhost(var.management_cluster_cidr, 1)}/${local.mc_subnet_mask}"
  }

  dynamic "tag" {
    for_each = var.tags

    content {
      scope = tag.value["scope"]
      tag   = tag.value["tag"]
    }
  }
}

resource "nsxt_policy_segment" "bastion-vmnet" {
  display_name        = format("%s-bastion-vmnet", var.cluster_name)
  connectivity_path   = var.tier1_gateway != "" ? data.nsxt_policy_tier1_gateway.tier1_gw_gateway[0].path : nsxt_policy_tier1_gateway.tier1_gw[0].path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay.path

  nsx_id = format("%s-bastion-vmnet", var.cluster_name)

  subnet {
    cidr = "${cidrhost(var.bastion_subnet_cidr, 1)}/${local.bastion_subnet_mask}"
  }

  dynamic "tag" {
    for_each = var.tags

    content {
      scope = tag.value["scope"]
      tag   = tag.value["tag"]
    }
  }
}
