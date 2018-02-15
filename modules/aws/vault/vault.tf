resource "aws_instance" "vault" {
  count         = "${var.vault_count}"
  ami           = "${var.container_linux_ami_id}"
  instance_type = "${var.instance_type}"

  associate_public_ip_address = false
  source_dest_check           = false
  subnet_id                   = "${var.vault_subnet_ids[count.index]}"
  vpc_security_group_ids      = ["${aws_security_group.vault.id}"]

  lifecycle {
    # Vault provisioned also by Ansible,
    # so prevent recreation if user_data or ami changed.
    ignore_changes = ["ami", "user_data"]
  }

  root_block_device = {
    volume_type = "${var.volume_type}"
    volume_size = "${var.volume_size_root}"
  }

  ebs_block_device = {
    device_name           = "/dev/xvdb"
    delete_on_termination = false
    volume_type           = "${var.volume_type}"
    volume_size           = "${var.volume_size_etcd}"
  }

  user_data = "${var.user_data}"

  tags = {
    Name        = "${var.cluster_name}-vault${count.index}"
    Environment = "${var.cluster_name}"
  }
}

resource "aws_security_group" "vault" {
  name   = "${var.cluster_name}-vault"
  vpc_id = "${var.vpc_id}"

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Vault API from vpc
  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  # Allow SSH from vpc
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  tags {
    Name        = "${var.cluster_name}-vault"
    Environment = "${var.cluster_name}"
  }
}

resource "aws_route53_record" "vault" {
  count   = "${var.vault_count}"
  zone_id = "${var.dns_zone_id}"
  name    = "vault${count.index + 1}"
  type    = "A"

  records = ["${element(aws_instance.vault.*.private_ip, count.index)}"]
  ttl     = "300"
}
