resource "aws_lb" "worker" {
  name                             = "${var.cluster_name}-worker"
  enable_cross_zone_load_balancing = true
  internal                         = false
  subnets                          = "${var.lb_subnet_ids}"
  load_balancer_type               = "network"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-worker"
    )
  )}"
}

resource "aws_lb_listener" "worker-80" {
  load_balancer_arn = "${aws_lb.worker.arn}"
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.worker-80.arn}"
  }
}

resource "aws_lb_listener" "worker-443" {
  load_balancer_arn = "${aws_lb.worker.arn}"
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.worker-443.arn}"
  }
}

resource "aws_lb_target_group" "worker-80" {
  name        = "worker-80"
  port        = 30010
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = "${var.vpc_id}"
}


resource "aws_lb_target_group" "worker-443" {
  name        = "worker-443"
  port        = 30011
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = "${var.vpc_id}"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    protocol            = "TCP"
    port                = 30011
  }
}

resource "aws_route53_record" "worker-wildcard" {
  count   = "${var.route53_enabled ? 1 : 0}"
  zone_id = "${var.dns_zone_id}"
  name    = "*"
  type    = "A"

  alias {
    name                   = "${aws_lb.worker.dns_name}"
    zone_id                = "${aws_lb.worker.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "worker-ingress" {
  count   = "${var.route53_enabled ? 1 : 0}"
  zone_id = "${var.dns_zone_id}"
  name    = "${var.ingress_dns}"
  type    = "A"

  alias {
    name                   = "${aws_lb.worker.dns_name}"
    zone_id                = "${aws_lb.worker.zone_id}"
    evaluate_target_health = false
  }
}
