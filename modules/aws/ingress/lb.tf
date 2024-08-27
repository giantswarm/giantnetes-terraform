locals {
  common_tags = merge(
  var.additional_tags,
  tomap({
  "giantswarm.io/cluster" =  var.cluster_name
  "giantswarm.io/installation" =  var.cluster_name
  "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  })
  )
}
resource "aws_elb" "worker" {
  name                      = "${var.cluster_name}-worker"
  cross_zone_load_balancing = true
  internal                  = false
  subnets                   = var.elb_subnet_ids
  security_groups           = [aws_security_group.worker_elb.id]

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
    tomap({
      "Name" = "${var.cluster_name}-worker"
    })
  )
}

resource "aws_proxy_protocol_policy" "worker" {
  load_balancer  = aws_elb.worker.name
  instance_ports = ["30010", "30011"]
}

resource "aws_security_group" "worker_elb" {
  name   = "${var.cluster_name}-worker-elb"
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
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "${var.cluster_name}-worker-elb"
    })
  )
}

resource "aws_route53_record" "worker-wildcard" {
  zone_id = var.dns_zone_id
  name    = "*"
  type    = "A"

  alias {
    name                   = aws_elb.worker.dns_name
    zone_id                = aws_elb.worker.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "worker-ingress" {
  zone_id = var.dns_zone_id
  name    = var.ingress_dns
  type    = "A"

  alias {
    name                   = aws_elb.worker.dns_name
    zone_id                = aws_elb.worker.zone_id
    evaluate_target_health = false
  }
}
