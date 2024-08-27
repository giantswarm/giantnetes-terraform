resource "aws_subnet" "bastion" {
  count = length(var.subnets_bastion)

  vpc_id            = aws_vpc.cluster_vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.subnets_bastion[count.index]

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "${var.cluster_name}-bastion${count.index}"
    })
  )
}

resource "aws_route_table_association" "bastion" {
  count = length(var.subnets_bastion)

  subnet_id      = aws_subnet.bastion[count.index].id
  route_table_id = var.with_public_access ? aws_route_table.cluster_vpc_public[count.index].id : aws_route_table.cluster_vpc_private[count.index].id
}
