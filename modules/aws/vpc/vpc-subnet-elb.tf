resource "aws_subnet" "elb" {
  count = min(length(data.aws_availability_zones.available.names),length(var.subnets_elb))

  vpc_id            = aws_vpc.cluster_vpc.id
  availability_zone = element(data.aws_availability_zones.available.names,count.index)
  cidr_block        = element(var.subnets_elb, count.index)

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "${var.cluster_name}-elb${count.index}"
    })
  )
}

resource "aws_route_table_association" "elb" {
  count = min(length(data.aws_availability_zones.available.names),length(var.subnets_elb))

  subnet_id      = element(aws_subnet.elb.*.id, count.index)
  route_table_id = element(aws_route_table.cluster_vpc_public.*.id, count.index)
}
