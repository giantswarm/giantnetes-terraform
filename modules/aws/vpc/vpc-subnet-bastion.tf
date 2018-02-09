resource "aws_subnet" "bastion_0" {
  vpc_id            = "${aws_vpc.cluster_vpc.id}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  cidr_block        = "${var.subnet_bastion_0}"

  tags {
    Name        = "${var.cluster_name}-bastion0"
    Environment = "${var.cluster_name}"
  }
}

resource "aws_subnet" "bastion_1" {
  vpc_id            = "${aws_vpc.cluster_vpc.id}"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  cidr_block        = "${var.subnet_bastion_1}"

  tags {
    Name        = "${var.cluster_name}-bastion1"
    Environment = "${var.cluster_name}"
  }
}

resource "aws_route_table_association" "bastion_0" {
  subnet_id      = "${aws_subnet.bastion_0.id}"
  route_table_id = "${aws_route_table.cluster_vpc_public_0.id}"
}

resource "aws_route_table_association" "bastion_1" {
  subnet_id      = "${aws_subnet.bastion_1.id}"
  route_table_id = "${aws_route_table.cluster_vpc_public_1.id}"
}
