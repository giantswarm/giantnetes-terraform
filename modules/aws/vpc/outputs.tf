output "bastion_subnet_ids" {
  value = ["${aws_subnet.bastion_0.id}", "${aws_subnet.bastion_1.id}"]
}

output "elb_subnet_ids" {
  value = ["${aws_subnet.elb_0.id}", "${aws_subnet.elb_1.id}", "${aws_subnet.elb_2.id}"]
}

output "vault_subnet_ids" {
  value = ["${aws_subnet.vault_0.id}"]
}

output "worker_subnet_ids" {
  value = ["${aws_subnet.worker_0.id}", "${aws_subnet.worker_1.id}", "${aws_subnet.worker_2.id}"]
}

output "private_route_table_ids" {
  value = ["${aws_route_table.cluster_vpc_private_0.id}", "${aws_route_table.cluster_vpc_private_1.id}", "${aws_route_table.cluster_vpc_private_2.id}"]
}

output "vpc_id" {
  value = "${aws_vpc.cluster_vpc.id}"
}
