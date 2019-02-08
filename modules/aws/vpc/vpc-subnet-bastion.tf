resource "aws_subnet" "bastion" {
  count = "${length(var.subnet_bastion)}"

  vpc_id            = "${aws_vpc.cluster_vpc.id}"
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"
  cidr_block        = "${element(var.subnet_bastion, count.index)}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-bastion${count.index}"
    )
  )}"
}

resource "aws_route_table_association" "bastion" {
  count = "${length(var.subnet_bastion)}"

  subnet_id      = "${element(aws_subnet.bastion.*.id,count.index)}"
  route_table_id = "${var.with_public_access == 0 ? element(aws_route_table.cluster_vpc_private.*.id,count.index) : element(aws_route_table.cluster_vpc_public.*.id,count.index)}"
}
