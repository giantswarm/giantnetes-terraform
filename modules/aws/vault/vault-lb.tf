resource "aws_lb" "vault" {
  name            = "${var.cluster_name}-vault"
  internal        = true
  subnets         = "${var.elb_subnet_ids}"
  security_groups = ["${aws_security_group.vault_elb.id}"]
  load_balancer_type               = "network"

  listener {
    instance_port     = "${var.vault_port}"
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

  tags = {
    Name                         = "${var.cluster_name}-vault"
    "giantswarm.io/installation" = "${var.cluster_name}"
  }
}

resource "aws_lb_listener" "vault" {
  load_balancer_arn = "${aws_lb.vault.arn}"
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.vault.arn}"
  }
}

resource "aws_lb_target_group" "vault" {
  name        = "vault"
  port        = "${var.vault_port}"
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_lb_target_group_attachment" "vault" {
  count            = "${var.vault_count}"
  target_group_arn = "${aws_lb_target_group.vault.arn}"
  target_id        = "${element(aws_instance.vault.*.id, count.index)}"
  port             = "${var.vault_port}"
}

resource "aws_route53_record" "vault-elb" {
  count   = "${var.route53_enabled ? 1 : 0}"
  zone_id = "${var.dns_zone_id}"
  name    = "${var.vault_dns}"
  type    = "A"

  alias {
    name                   = "${aws_elb.vault.dns_name}"
    zone_id                = "${aws_elb.vault.zone_id}"
    evaluate_target_health = false
  }
}
