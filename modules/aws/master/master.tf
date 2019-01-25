locals {
  common_tags = "${map(
    "giantswarm.io/installation", "${var.cluster_name}",
    "kubernetes.io/cluster/${var.cluster_name}", "owned"
  )}"
}

data "aws_availability_zones" "available" {}

resource "aws_instance" "master" {
  count                = "${var.master_count}"
  ami                  = "${var.container_linux_ami_id}"
  instance_type        = "${var.instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.master.name}"

  associate_public_ip_address = false
  source_dest_check           = false

  # TODO: change to count.index after resolving the  subnets
  subnet_id              = "${var.master_subnet_ids[count.index]}"
  vpc_security_group_ids = ["${aws_security_group.master.id}"]

  root_block_device = {
    volume_type = "${var.volume_type}"
    volume_size = "${var.volume_size_root}"
  }

  user_data = "${element(data.ignition_config.s3.*.rendered, count.index)}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-master${count.index}"
    )
  )}"

  # we ignore changes, to avoid rolling all masters at once
  # update is done via tainting masters
  lifecycle {
    ignore_changes = ["*"]
  }
}

resource "aws_ebs_volume" "master_docker" {
  count = "${var.master_count}"

  # TODO: change to count.index after resolving the  subnets
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"
  size              = "${var.volume_size_docker}"
  type              = "${var.volume_type}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-master${count.index+1}-docker"
    )
  )}"
}

resource "aws_volume_attachment" "master_docker" {
  count       = "${var.master_count}"
  device_name = "${var.volume_docker}"
  volume_id   = "${element(aws_ebs_volume.master_docker.*.id, count.index)}"
  instance_id = "${element(aws_instance.master.*.id, count.index)}"

  # Allows reattaching volume.
  skip_destroy = true
}

resource "aws_ebs_volume" "master_etcd" {
  count = "${var.master_count}"

  # TODO: change to count.index after resolving the subnets
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"
  size              = "${var.volume_size_etcd}"
  type              = "${var.volume_type}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-master${count.index+1}-etcd"
    )
  )}"
}

resource "aws_volume_attachment" "master_etcd" {
  count = "${var.master_count}"

  # NOTE: For m5 type we must use xvdh here to guarantee that
  # that disk will be the second one.
  device_name = "${var.volume_etcd}"

  volume_id   = "${element(aws_ebs_volume.master_etcd.*.id, count.index)}"
  instance_id = "${element(aws_instance.master.*.id, count.index)}"

  # Allows reattaching volume.
  skip_destroy = true

  depends_on = ["aws_volume_attachment.master_docker"]
}

resource "aws_security_group" "master" {
  name   = "${var.cluster_name}-master"
  vpc_id = "${var.vpc_id}"

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow access from vpc
  ingress {
    from_port   = 10
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  # Allow access from vpc
  ingress {
    from_port   = 10
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  # Allow IPIP traffic from vpc
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = 4
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-master"
    )
  )}"
}

resource "aws_route53_record" "master" {
  count   = "${var.route53_enabled ? var.master_count : 0}"
  zone_id = "${var.dns_zone_id}"
  name    = "master{count.index+1}"
  type    = "CNAME"
  records = ["${element(aws_instance.master.*.private_dns, count.index)}"]
  ttl     = "30"
}

resource "aws_route53_record" "etcd" {
  count   = "${var.route53_enabled ? var.master_count : 0}"
  zone_id = "${var.dns_zone_id}"
  name    = "etcd${count.index+1}"
  type    = "CNAME"
  records = ["${element(aws_instance.master.*.private_dns, count.index)}"]
  ttl     = "30"
}

# To avoid 16kb user_data limit upload CoreOS ignition config to a s3 bucket.
# Ignition supports s3 out-of-the-box.
resource "aws_s3_bucket_object" "ignition_master_with_tags" {
  count   = "${var.s3_bucket_tags ? var.master_count : 0}"
  bucket  = "${var.ignition_bucket_id}"
  key     = "${var.cluster_name}-ignition-master${count.index+1}.json"
  content = "${replace(var.user_data, "__MASTER_ID__",count.index+1)}"
  acl     = "private"

  server_side_encryption = "AES256"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-ignition-master"
    )
  )}"
}

# To avoid 16kb user_data limit upload CoreOS ignition config to a s3 bucket.
# Ignition supports s3 out-of-the-box.
resource "aws_s3_bucket_object" "ignition_master_without_tags" {
  count   = "${var.s3_bucket_tags ? 0 : var.master_count}"
  bucket  = "${var.ignition_bucket_id}"
  key     = "${var.cluster_name}-ignition-master${count.index+1}.json"
  content = "${replace(var.user_data, "__MASTER_ID__",count.index+1)}"
  acl     = "private"

  server_side_encryption = "AES256"
}

locals {
  # In China there is no tags for s3 buckets
  s3_ignition_master_keys = "${concat(aws_s3_bucket_object.ignition_master_with_tags.*.key, aws_s3_bucket_object.ignition_master_without_tags.*.key)}"
}

data "ignition_config" "s3" {
  count = "${var.master_count}"

  replace {
    source       = "${format("s3://%s/%s", var.ignition_bucket_id, element(local.s3_ignition_master_keys, count.index))}"
    verification = "sha512-${sha512(replace(var.user_data, "__MASTER_ID__",count.index+1))}"
  }
}
