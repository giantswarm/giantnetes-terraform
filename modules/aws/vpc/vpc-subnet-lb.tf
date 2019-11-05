resource "aws_subnet" "lb" {
  count = "${min(length(data.aws_availability_zones.available.names),length(var.subnets_lb))}"

  vpc_id            = "${aws_vpc.cluster_vpc.id}"
  availability_zone = "${element(data.aws_availability_zones.available.names,count.index)}"
  cidr_block        = "${element(var.subnets_lb, count.index)}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-lb${count.index}"
    )
  )}"
}

resource "aws_route_table_association" "lb" {
  count = "${min(length(data.aws_availability_zones.available.names),length(var.subnets_lb))}"

  subnet_id      = "${element(aws_subnet.lb.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.cluster_vpc_public.*.id, count.index)}"
}
