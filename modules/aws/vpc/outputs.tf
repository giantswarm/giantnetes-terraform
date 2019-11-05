output "bastion_subnet_ids" {
  value = "${aws_subnet.bastion.*.id}"
}

output "lb_subnet_ids" {
  value = "${aws_subnet.lb.*.id}"
}

output "vault_subnet_ids" {
  value = ["${aws_subnet.vault_0.id}"]
}

output "worker_subnet_ids" {
  value = "${aws_subnet.worker.*.id}"
}

output "private_route_table_ids" {
  value = "${aws_route_table.cluster_vpc_private.*.id}"
}

output "vpc_id" {
  value = "${aws_vpc.cluster_vpc.id}"
}
