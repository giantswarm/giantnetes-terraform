resource "aws_elb" "private_worker" {
  name                      = "${var.cluster_name}-private-worker"
  cross_zone_load_balancing = true
  internal                  = true
  subnets                   = var.elb_subnet_ids
  security_groups           = ["${aws_security_group.worker_elb.id}"]

  listener {
    instance_port     = 30010
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 30011
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 4
    target              = "TCP:30011"
    interval            = 5
  }

  tags = merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-private-worker"
    )
  )
}

resource "aws_security_group" "private_worker_elb" {
  name   = "${var.cluster_name}-private-worker-elb"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  tags = merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-private-worker-elb"
    )
  )
}

resource "aws_route53_record" "private-worker-wildcard" {
  count   = var.route53_enabled ? 1 : 0
  zone_id = var.private_dns_zone_id
  name    = "*"
  type    = "A"

  alias {
    name                   = aws_elb.private_worker.dns_name
    zone_id                = aws_elb.private_worker.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "private-worker-ingress" {
  count   = var.route53_enabled ? 1 : 0
  zone_id = var.private_dns_zone_id
  name    = var.ingress_dns
  type    = "A"

  alias {
    name                   = aws_elb.private_worker.dns_name
    zone_id                = aws_elb.private_worker.zone_id
    evaluate_target_health = false
  }
}
