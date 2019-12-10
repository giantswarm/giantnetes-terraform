resource "aws_lb" "master_api" {
  name                             = "${var.cluster_name}-master-api"
  enable_cross_zone_load_balancing = true
  idle_timeout                     = 3600
  internal                         = true
  subnets                          = "${var.lb_subnet_ids}"
  load_balancer_type               = "network"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-master-api"
    )
  )}"
}

resource "aws_lb_listener" "master" {
  load_balancer_arn = "${aws_lb.master_api.arn}"
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.master_api.arn}"
  }
}

resource "aws_lb_target_group" "master_api" {
  name        = "${var.cluster_name}-master"
  port        = 443
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = "${var.vpc_id}"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    protocol            = "HTTP"
    path                = "/healthz"
    interval            = 10
    port                = 8089
  }
}

resource "aws_lb_target_group_attachment" "master_api" {
  count            = "${var.master_count}"
  target_group_arn = "${aws_lb_target_group.master_api.arn}"
  target_id        = "${element(aws_instance.master.*.id, count.index)}"
  port             = 443
}

resource "aws_route53_record" "master_api" {
  count   = "${var.route53_enabled ? 1 : 0}"
  zone_id = "${var.dns_zone_id}"
  name    = "${var.api_dns}"
  type    = "A"

  alias {
    name                   = "${aws_lb.master_api.dns_name}"
    zone_id                = "${aws_lb.master_api.zone_id}"
    evaluate_target_health = false
  }
}
