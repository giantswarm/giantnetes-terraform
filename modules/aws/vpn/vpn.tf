# site2site vpn for access to bastion

variable "aws_cluster_name" {}
variable "aws_customer_gateway_id_0" {}
variable "aws_external_ipsec_subnet_0" {}
variable "aws_customer_gateway_id_1" {}
variable "aws_external_ipsec_subnet_1" {}
variable "aws_vpn_name" {}
variable "aws_vpn_vpc_id" {}

variable "aws_private_route_table_ids" {
  type = "list"
}

resource "aws_vpn_gateway" "vpn_gw" {
  count  = "${var.aws_customer_gateway_id_0 == "" ? 0 : 1}"
  vpc_id = "${var.aws_vpn_vpc_id}"

  tags = {
    Name                         = "${var.aws_vpn_name}"
    "giantswarm.io/installation" = "${var.aws_cluster_name}"
  }
}

data "aws_vpn_gateway" "vpn_gw" {
  # Workaround for a bug that claimed to be addressed by 0.12 version.
  # https://github.com/hashicorp/terraform/issues/12570
  count = "${var.aws_customer_gateway_id_0 == "" ? 0 : 1}"

  id = "${aws_vpn_gateway.vpn_gw.*.id[count.index]}"
}

resource "aws_vpn_connection" "aws_vpn_conn_0" {
  count               = "${var.aws_customer_gateway_id_0 == "" ? 0 : 1}"
  vpn_gateway_id      = "${aws_vpn_gateway.vpn_gw.*.id[count.index]}"
  customer_gateway_id = "${var.aws_customer_gateway_id_0}"
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
    Name                         = "${var.aws_vpn_name}-0"
    "giantswarm.io/installation" = "${var.aws_cluster_name}"
  }
}

resource "aws_vpn_connection" "aws_vpn_conn_1" {
  count               = "${var.aws_customer_gateway_id_0 == "" ? 0 : 1}"
  vpn_gateway_id      = "${aws_vpn_gateway.vpn_gw.*.id[count.index]}"
  customer_gateway_id = "${var.aws_customer_gateway_id_1}"
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
    Name                         = "${var.aws_vpn_name}-1"
    "giantswarm.io/installation" = "${var.aws_cluster_name}"
  }
}

resource "aws_vpn_connection_route" "customer_network_0" {
  count                  = "${var.aws_customer_gateway_id_0 == "" ? 0 : 1}"
  destination_cidr_block = "${var.aws_external_ipsec_subnet_0}"
  vpn_connection_id      = "${aws_vpn_connection.aws_vpn_conn_0.*.id[count.index]}"
}

resource "aws_vpn_connection_route" "customer_network_1" {
  count                  = "${var.aws_customer_gateway_id_1 == "" ? 0 : 1}"
  destination_cidr_block = "${var.aws_external_ipsec_subnet_1}"
  vpn_connection_id      = "${aws_vpn_connection.aws_vpn_conn_1.*.id[count.index]}"
}

# Add vpc routes that point to VPN gateways.
resource "aws_route" "vpc_route_0" {
  count                  = "${var.aws_customer_gateway_id_0 == "" ? 0 : 2}"
  route_table_id         = "${var.aws_private_route_table_ids[count.index]}"
  destination_cidr_block = "${var.aws_external_ipsec_subnet_0}"
  gateway_id             = "${aws_vpn_gateway.vpn_gw[0].id}"
}

resource "aws_route" "vpc_route_1" {
  count                  = "${var.aws_customer_gateway_id_1 == "" ? 0 : 2}"
  route_table_id         = "${var.aws_private_route_table_ids[count.index]}"
  destination_cidr_block = "${var.aws_external_ipsec_subnet_1}"
  gateway_id             = "${aws_vpn_gateway.vpn_gw[0].id}"
}
