data "aws_availability_zones" "available" {}

resource "aws_instance" "master" {
  count                = "${var.master_count}"
  ami                  = "${var.container_linux_ami_id}"
  instance_type        = "${var.instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.master.name}"

  associate_public_ip_address = false
  source_dest_check           = false
  subnet_id                   = "${var.master_subnet_ids[count.index]}"
  vpc_security_group_ids      = ["${aws_security_group.master.id}"]

  root_block_device = {
    volume_type = "${var.volume_type}"
    volume_size = "${var.volume_size_root}"
  }

  user_data = "${data.ignition_config.s3.rendered}"

  tags = {
    Name              = "${var.cluster_name}-master${count.index}"
    Environment       = "${var.cluster_name}"
    KubernetesCluster = "${var.cluster_name}"
  }
}

resource "aws_ebs_volume" "master_docker" {
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  size              = "${var.volume_size_docker}"
  type              = "${var.volume_type}"

  tags {
    Name        = "${var.cluster_name}-master"
    Environment = "${var.cluster_name}"
  }
}

resource "aws_volume_attachment" "master_docker" {
  device_name = "/dev/xvdc"
  volume_id   = "${aws_ebs_volume.master_docker.id}"
  instance_id = "${aws_instance.master.id}"

  # Allows reattaching volume.
  skip_destroy = true
}

resource "aws_ebs_volume" "master_etcd" {
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  size              = "${var.volume_size_etcd}"
  type              = "${var.volume_type}"

  tags {
    Name        = "${var.cluster_name}-master"
    Environment = "${var.cluster_name}"
  }
}

resource "aws_volume_attachment" "master_etcd" {
  device_name = "/dev/xvdd"
  volume_id   = "${aws_ebs_volume.master_etcd.id}"
  instance_id = "${aws_instance.master.id}"

  # Allows reattaching volume.
  skip_destroy = true
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

  tags {
    Name        = "${var.cluster_name}-master"
    Environment = "${var.cluster_name}"
  }
}

resource "aws_route53_record" "master" {
  count   = "${var.master_count}"
  zone_id = "${var.dns_zone_id}"
  name    = "master${count.index + 1}"
  type    = "CNAME"
  records = ["${element(aws_instance.master.*.private_dns, count.index)}"]
  ttl     = "300"
}

# NOTE: This works only for the case with one master.
resource "aws_route53_record" "etcd" {
  zone_id = "${var.dns_zone_id}"
  name    = "etcd"
  type    = "CNAME"
  records = ["${aws_instance.master.0.private_dns}"]
  ttl     = "300"
}

# To avoid 16kb user_data limit upload CoreOS ignition config to a s3 bucket.
# Ignition supports s3 out-of-the-box.
resource "aws_s3_bucket_object" "ignition_master" {
  bucket  = "${var.ignition_bucket_id}"
  key     = "${var.cluster_name}-ignition-master.json"
  content = "${var.user_data}"
  acl     = "private"

  server_side_encryption = "AES256"

  tags = {
    Name        = "${var.cluster_name}-ignition-master"
    Environment = "${var.cluster_name}"
  }
}

data "ignition_config" "s3" {
  replace {
    source       = "${format("s3://%s/%s", var.ignition_bucket_id, aws_s3_bucket_object.ignition_master.key)}"
    verification = "sha512-${sha512(var.user_data)}"
  }
}
