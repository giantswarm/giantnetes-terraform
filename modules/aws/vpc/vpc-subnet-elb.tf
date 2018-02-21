resource "aws_subnet" "elb_0" {
  vpc_id            = "${aws_vpc.cluster_vpc.id}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  cidr_block        = "${var.subnet_elb_0}"

  tags {
    Name        = "${var.cluster_name}-elb0"
    Environment = "${var.cluster_name}"
  }
}

resource "aws_subnet" "elb_1" {
  vpc_id            = "${aws_vpc.cluster_vpc.id}"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  cidr_block        = "${var.subnet_elb_1}"

  tags {
    Name        = "${var.cluster_name}-elb1"
    Environment = "${var.cluster_name}"
  }
}

resource "aws_route_table_association" "elb_0" {
  subnet_id      = "${aws_subnet.elb_0.id}"
  route_table_id = "${aws_route_table.cluster_vpc_public_0.id}"
}

resource "aws_route_table_association" "elb_1" {
  subnet_id      = "${aws_subnet.elb_1.id}"
  route_table_id = "${aws_route_table.cluster_vpc_public_1.id}"
}
