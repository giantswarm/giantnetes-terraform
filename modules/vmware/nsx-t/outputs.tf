output "vm_network" {
  value = nsxt_policy_segment.vmnet1.display_name
}

output "bastion_network" {
  value = nsxt_policy_segment.bastion-vmnet.display_name
}
