resource "aws_subnet" "worker_0" {
  vpc_id            = "${aws_vpc.cluster_vpc.id}"
  availability_zone = "${element(data.aws_availability_zones.available.names,0)}"
  cidr_block        = "${var.subnet_worker_0}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-worker0"
    )
  )}"
}

resource "aws_subnet" "worker_1" {
  vpc_id            = "${aws_vpc.cluster_vpc.id}"
  availability_zone = "${element(data.aws_availability_zones.available.names,1)}"
  cidr_block        = "${var.subnet_worker_1}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-worker1"
    )
  )}"
}

resource "aws_subnet" "worker_2" {
  vpc_id            = "${aws_vpc.cluster_vpc.id}"
  availability_zone = "${element(data.aws_availability_zones.available.names,2)}"
  cidr_block        = "${var.subnet_worker_2}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-worker2"
    )
  )}"
}

resource "aws_route_table_association" "worker_0" {
  subnet_id      = "${aws_subnet.worker_0.id}"
  route_table_id = "${aws_route_table.cluster_vpc_private_0.id}"
}

resource "aws_route_table_association" "worker_1" {
  subnet_id      = "${aws_subnet.worker_1.id}"
  route_table_id = "${aws_route_table.cluster_vpc_private_1.id}"
}

resource "aws_route_table_association" "worker_2" {
  subnet_id      = "${aws_subnet.worker_2.id}"
  route_table_id = "${aws_route_table.cluster_vpc_private_2.id}"
}
