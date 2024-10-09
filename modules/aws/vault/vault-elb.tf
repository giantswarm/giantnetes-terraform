resource "aws_elb" "vault" {
  name            = "${var.cluster_name}-vault"
  internal        = true
  subnets         = var.elb_subnet_ids
  security_groups = [aws_security_group.vault_elb.id]

  listener {
    instance_port     = var.vault_port
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 4
    target              = "TCP:${var.vault_port}"
    interval            = 5
  }

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "${var.cluster_name}-vault"
    })
  )
}

resource "aws_elb_attachment" "vault" {
  count         = var.vault_count
  elb      = aws_elb.vault.id
  instance = aws_instance.vault[count.index].id
}

resource "aws_security_group" "vault_elb" {
  name   = "${var.cluster_name}-vault-elb"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr, var.aws_cni_cidr_block]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.ipam_network_cidr]
  }

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "${var.cluster_name}-vault-elb"
    })
  )
}

resource "aws_route53_record" "vault-elb" {
  zone_id = var.dns_zone_id
  name    = var.vault_dns
  type    = "A"

  alias {
    name                   = aws_elb.vault.dns_name
    zone_id                = aws_elb.vault.zone_id
    evaluate_target_health = false
  }
}
