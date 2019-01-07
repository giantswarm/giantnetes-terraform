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

resource "aws_nat_gateway" "private_nat_gateway_0" {
  allocation_id = "${aws_eip.private_nat_gateway_0.id}"
  subnet_id     = "${aws_subnet.elb_0.id}"
}

resource "aws_nat_gateway" "private_nat_gateway_1" {
  allocation_id = "${aws_eip.private_nat_gateway_1.id}"
  subnet_id     = "${aws_subnet.elb_1.id}"
}

resource "aws_nat_gateway" "private_nat_gateway_2" {
  allocation_id = "${aws_eip.private_nat_gateway_2.id}"
  subnet_id     = "${aws_subnet.elb_2.id}"
}

resource "aws_eip" "private_nat_gateway_0" {
  vpc = true

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-private-nat-gateway0"
    )
  )}"
}

resource "aws_eip" "private_nat_gateway_1" {
  vpc = true

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-private-nat-gateway1"
    )
  )}"
}

resource "aws_eip" "private_nat_gateway_2" {
  vpc = true

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-private-nat-gateway2"
    )
  )}"
}

resource "aws_route_table" "cluster_vpc_private_0" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}_private_0"
    )
  )}"
}

resource "aws_route_table" "cluster_vpc_private_1" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}_private_1"
    )
  )}"
}

resource "aws_route_table" "cluster_vpc_private_2" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}_private_2"
    )
  )}"
}

resource "aws_route_table" "cluster_vpc_public_0" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-public0"
    )
  )}"
}

resource "aws_route_table" "cluster_vpc_public_1" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-public1"
    )
  )}"
}

resource "aws_route_table" "cluster_vpc_public_2" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-public2"
    )
  )}"
}

resource "aws_route" "vpc_local_route_0" {
  route_table_id         = "${aws_route_table.cluster_vpc_public_0.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.cluster_vpc.id}"
  depends_on             = ["aws_route_table.cluster_vpc_public_0"]
}

resource "aws_route" "vpc_local_route_1" {
  route_table_id         = "${aws_route_table.cluster_vpc_public_1.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.cluster_vpc.id}"
  depends_on             = ["aws_route_table.cluster_vpc_public_1"]
}

resource "aws_route" "vpc_local_route_2" {
  route_table_id         = "${aws_route_table.cluster_vpc_public_2.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.cluster_vpc.id}"
  depends_on             = ["aws_route_table.cluster_vpc_public_2"]
}

resource "aws_route" "private_nat_gateway_0" {
  route_table_id         = "${aws_route_table.cluster_vpc_private_0.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.private_nat_gateway_0.id}"
}

resource "aws_route" "private_nat_gateway_1" {
  route_table_id         = "${aws_route_table.cluster_vpc_private_1.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.private_nat_gateway_1.id}"
}

resource "aws_route" "private_nat_gateway_2" {
  route_table_id         = "${aws_route_table.cluster_vpc_private_2.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.private_nat_gateway_2.id}"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = "${aws_vpc.cluster_vpc.id}"
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  route_table_ids = [
    "${aws_route_table.cluster_vpc_private_0.id}",
    "${aws_route_table.cluster_vpc_private_1.id}",
    "${aws_route_table.cluster_vpc_private_2.id}",
    "${aws_route_table.cluster_vpc_public_0.id}",
    "${aws_route_table.cluster_vpc_public_1.id}",
    "${aws_route_table.cluster_vpc_public_2.id}",
  ]

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
