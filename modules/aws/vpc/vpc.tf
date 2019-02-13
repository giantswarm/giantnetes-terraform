# Following networking schema implemented:
#
#   * a public route table with the internet gateway as a default route
#   * a private route table with the private nat gateway as a default route
#   * elb subnets are using the public route table
#   * bastion, vault and worker subnets are using the private route table
#   * the private nat gateway is in the elb subnet as well (needs to be in a public subnet)

locals {
  common_tags = "${map(
    "giantswarm.io/installation", "${var.cluster_name}",
    "kubernetes.io/cluster/${var.cluster_name}", "owned"
  )}"

  policy_allow = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "Allow-All-Rule",
      "Principal": "*",
      "Action": "*",
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF

  policy_strict = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "Host-Cluster-Rule",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Effect": "Allow",
      "Resource": "arn:${var.arn_region}:s3:::${var.aws_account}-${var.cluster_name}-ignition/*"
    },
    {
      "Sid": "Etcd-Backup-Rule",
      "Principal": "*",
      "Action": "*",
      "Effect": "Allow",
      "Resource": "arn:${var.arn_region}:s3:::etcd-backups.giantswarm.io/*"
    },
    {
      "Sid": "AWS-Operator-Rule",
      "Principal": "*",
      "Action": "*",
      "Effect": "Allow",
      "Resource": "arn:${var.arn_region}:s3:::*-g8s-*"
    }
  ]
}
EOF
}

data "aws_availability_zones" "available" {}

data "aws_region" "current" {}

resource "aws_vpc" "cluster_vpc" {
  cidr_block = "${var.vpc_cidr}"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}"
    )
  )}"
}

resource "aws_internet_gateway" "cluster_vpc" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}"
    )
  )}"
}

resource "aws_nat_gateway" "private_nat_gateway" {
  count = "${length(var.subnets_elb)}"

  allocation_id = "${element(aws_eip.private_nat_gateway.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.elb.*.id, count.index)}"
}

resource "aws_eip" "private_nat_gateway" {
  count = "${length(var.subnets_elb)}"
  vpc   = true

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-private-nat-gateway${count.index}"
    )
  )}"
}

resource "aws_route_table" "cluster_vpc_private" {
  count  = "${length(var.subnets_worker)}"
  vpc_id = "${aws_vpc.cluster_vpc.id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}_private_${count.index}"
    )
  )}"
}

resource "aws_route_table" "cluster_vpc_public" {
  count  = "${length(var.subnets_elb)}"
  vpc_id = "${aws_vpc.cluster_vpc.id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-public${count.index}"
    )
  )}"
}

resource "aws_route" "vpc_local_route" {
  count = "${length(var.subnets_elb)}"

  route_table_id         = "${element(aws_route_table.cluster_vpc_public.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.cluster_vpc.id}"
  depends_on             = ["aws_route_table.cluster_vpc_public"]
}

resource "aws_route" "private_nat_gateway" {
  count = "${length(var.subnets_worker)}"

  route_table_id         = "${element(aws_route_table.cluster_vpc_private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.private_nat_gateway.*.id, count.index)}"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = "${aws_vpc.cluster_vpc.id}"
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  route_table_ids = ["${concat(aws_route_table.cluster_vpc_private.*.id, aws_route_table.cluster_vpc_public.*.id)}"]

  # Use allow all policy for for us-east-1. Problem that github, bitbucket
  # and quay are hosted in us-east-1 (other US?) and accessing these resources thru
  # endpoint results into 403 errors.
  policy = "${data.aws_region.current.name == "us-east-1" ? local.policy_allow : local.policy_strict}"
}

# Deny all traffic in default sec.group.
resource "aws_default_security_group" "default" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"

  # Specifying w/o rules deletes all existing rules
  # https://www.terraform.io/docs/providers/aws/r/default_security_group.html
}
