resource "aws_elb" "public_master_api" {
  name                      = "${var.cluster_name}-public-master-api"
  cross_zone_load_balancing = true
  idle_timeout              = 3600
  internal                  = false
  subnets                   = var.elb_subnet_ids
  security_groups           = ["${aws_security_group.public_master_elb_api.id}"]

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 4
    target              = "HTTP:8089/healthz"
    interval            = 5
  }

  tags = merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-public-master-api"
    )
  )
}

resource "aws_security_group" "public_master_elb_api" {
  name   = "${var.cluster_name}-public-master-elb-api"
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
    cidr_blocks = ["0.0.0.0/0"] # temporary allow all due to China case
  }

  tags = merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-public-master-elb-api"
    )
  )
}

resource "aws_route53_record" "public_master_elb_api" {
  count   = var.route53_enabled ? 1 : 0
  zone_id = var.public_dns_zone_id
  name    = var.api_dns
  type    = "A"

  alias {
    name                   = aws_elb.public_master_api.dns_name
    zone_id                = aws_elb.public_master_api.zone_id
    evaluate_target_health = false
  }
}
