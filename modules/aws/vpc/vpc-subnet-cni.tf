resource "aws_vpc_ipv4_cidr_block_association" "cni_v2" {
  vpc_id     = aws_vpc.cluster_vpc.id
  cidr_block = var.aws_cni_cidr_v2
}

resource "aws_subnet" "cni_v2" {
  count = length(var.aws_cni_subnets_v2)

  vpc_id            = aws_vpc.cluster_vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.aws_cni_subnets_v2[count.index]

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "${var.cluster_name}-cni_v2-${count.index}"
    })
  )
  depends_on = [aws_vpc_ipv4_cidr_block_association.cni_v2]
}

resource "aws_route_table_association" "cni" {
  count = length(var.aws_cni_subnets_v2)

  subnet_id      = aws_subnet.cni_v2[count.index].id
  route_table_id = aws_route_table.cluster_vpc_private[count.index].id
}

resource "aws_security_group" "cni" {
  name        = "${var.cluster_name}-cni"
  description = "AWS CNI pod security group"
  vpc_id      = aws_vpc.cluster_vpc.id

  ingress {
    description = "Allow traffic from vpc."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr, var.aws_cni_cidr_v2]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "${var.cluster_name}-cni"
    })
  )
}

