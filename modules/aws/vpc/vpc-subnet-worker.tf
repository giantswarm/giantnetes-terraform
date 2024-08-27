resource "aws_subnet" "worker" {
  count = length(var.subnets_worker)

  vpc_id            = aws_vpc.cluster_vpc.id
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  cidr_block        = element(var.subnets_worker, count.index)

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "${var.cluster_name}-worker${count.index}"
    })
  )
}

resource "aws_route_table_association" "worker" {
  count = length(var.subnets_worker)

  subnet_id      = element(aws_subnet.worker.*.id, count.index)
  route_table_id = element(aws_route_table.cluster_vpc_private.*.id, count.index)
}
