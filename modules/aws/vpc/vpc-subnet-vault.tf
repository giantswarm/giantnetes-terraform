resource "aws_subnet" "vault_0" {
  vpc_id            = "${aws_vpc.cluster_vpc.id}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  cidr_block        = "${var.subnet_vault_0}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-vault0"
    )
  )}"
}

resource "aws_route_table_association" "vault_0" {
  subnet_id      = "${aws_subnet.vault_0.id}"
  route_table_id = "${aws_route_table.cluster_vpc_private_0.id}"
}
