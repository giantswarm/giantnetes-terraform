output "aws_cni_security_group_id" {
  value = aws_security_group.cni.id
}

output "aws_cni_subnet_ids" {
  value = aws_subnet.cni_v2.*.id
}

output "aws_eip_public_ips" {
  value = aws_eip.private_nat_gateway.*.public_ip
}

output "bastion_subnet_ids" {
  value = aws_subnet.bastion.*.id
}

output "elb_subnet_ids" {
  value = aws_subnet.elb.*.id
}

output "vault_subnet_ids" {
  value = [aws_subnet.vault_0.id]
}

output "worker_subnet_ids" {
  value = aws_subnet.worker.*.id
}

output "private_route_table_ids" {
  value = aws_route_table.cluster_vpc_private.*.id
}

output "vpc_id" {
  value = aws_vpc.cluster_vpc.id
}
