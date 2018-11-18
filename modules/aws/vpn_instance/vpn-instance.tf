locals {
  # In China there is no tags for s3 buckets
  s3_ignition_vpn_instance_key = "${element(concat(aws_s3_bucket_object.ignition_vpn_instance_with_tags.*.key, aws_s3_bucket_object.ignition_vpn_instance_without_tags.*.key), 0)}"

  common_tags = "${map(
    "giantswarm.io/installation", "${var.cluster_name}",
    "kubernetes.io/cluster/${var.cluster_name}", "owned"
  )}"
}

data "aws_region" "current" {}

resource "aws_instance" "vpn_instance" {
  count                = "${var.vpn_instance_enabled ? 1 : 0}"
  ami                  = "${var.container_linux_ami_id}"
  instance_type        = "${var.instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.vpn_instance.name}"

  associate_public_ip_address = true
  source_dest_check           = false
  subnet_id                   = "${var.bastion_subnet_ids[count.index]}"
  vpc_security_group_ids      = ["${aws_security_group.vpn_instance.id}"]

  root_block_device = {
    volume_type = "${var.volume_type}"
    volume_size = "${var.volume_size_root}"
  }

  user_data = "${data.ignition_config.s3.rendered}"

  tags = {
    Name                         = "${var.cluster_name}-vpn-instance${count.index}"
    "giantswarm.io/installation" = "${var.cluster_name}"
  }
}

resource "aws_eip" "vpn_eip" {
  count = "${var.vpn_instance_enabled ? 1 : 0}"
  vpc   = true
}

resource "aws_eip_association" "vpn_eip" {
  count         = "${var.vpn_instance_enabled ? 1 : 0}"
  instance_id   = "${aws_instance.vpn_instance.id}"
  allocation_id = "${aws_eip.vpn_eip.id}"
}

resource "aws_security_group" "vpn_instance" {
  count  = "${var.vpn_instance_enabled ? 1 : 0}"
  name   = "${var.cluster_name}-vpn-instance"
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

  # Allow any traffic from VPN servers
  ingress {
    from_port   = 10
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${var.external_vpn_cidr_0}", "${var.external_vpn_cidr_1}"]
    self        = true
  }

  # Allow any traffic from VPN servers
  ingress {
    from_port   = 10
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["${var.external_vpn_cidr_0}", "${var.external_vpn_cidr_1}"]
    self        = true
  }

  tags {
    Name                         = "${var.cluster_name}-vpn-instance"
    "giantswarm.io/installation" = "${var.cluster_name}"
  }
}

resource "aws_route53_record" "vpn_instance" {
  count   = "${var.route53_enabled && var.vpn_instance_enabled ? 1 : 0}"
  zone_id = "${var.dns_zone_id}"
  name    = "vpn-instance${count.index + 1}"
  type    = "A"

  # Add "public_ip" or "private_ip" depending on "with_public_access" parameter.
  records = ["element(aws_instance.vpn_instance.*.public_ip, count.index)"]
  ttl     = "300"
}

# To avoid 16kb user_data limit upload CoreOS ignition config to a s3 bucket.
# Ignition supports s3 out-of-the-box.
resource "aws_s3_bucket_object" "ignition_vpn_instance_with_tags" {
  count   = "${var.s3_bucket_tags && var.vpn_instance_enabled ? 1 : 0}"
  bucket  = "${var.ignition_bucket_id}"
  key     = "${var.cluster_name}-ignition-vpn-instance.json"
  content = "${var.user_data}"
  acl     = "private"

  server_side_encryption = "AES256"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-ignition-vpn-instance"
    )
  )}"
}

resource "aws_s3_bucket_object" "ignition_vpn_instance_without_tags" {
  count   = "${!var.s3_bucket_tags && var.vpn_instance_enabled ? 1 : 0}"
  bucket  = "${var.ignition_bucket_id}"
  key     = "${var.cluster_name}-ignition-vpn-instance.json"
  content = "${var.user_data}"
  acl     = "private"

  server_side_encryption = "AES256"
}

data "ignition_config" "s3" {
  count = "${var.vpn_instance_enabled ? 1 : 0}"

  replace {
    source       = "${format("s3://%s/%s", var.ignition_bucket_id, local.s3_ignition_vpn_instance_key)}"
    verification = "sha512-${sha512(var.user_data)}"
  }
}
