resource "aws_elb" "master" {
  name                      = "${var.cluster_name}-master"
  cross_zone_load_balancing = true
  idle_timeout              = 3600
  internal                  = true
  subnets                   = ["${var.elb_subnet_ids}"]
  security_groups           = ["${aws_security_group.master_elb.id}"]

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    target              = "TCP:443"
    interval            = 15
  }

  tags {
    Name        = "${var.cluster_name}-master"
    Environment = "${var.cluster_name}"
  }
}

resource "aws_elb_attachment" "master" {
  elb      = "${aws_elb.master.id}"
  instance = "${aws_instance.master.id}"
}

resource "aws_security_group" "master_elb" {
  name   = "${var.cluster_name}-master-elb"
  vpc_id = "${var.vpc_id}"

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
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.cluster_name}-master-elb"
    Environment = "${var.cluster_name}"
  }
}

resource "aws_route53_record" "master-api" {
  zone_id = "${var.dns_zone_id}"
  name    = "${var.api_dns}"
  type    = "A"

  alias {
    name                   = "${aws_elb.master.dns_name}"
    zone_id                = "${aws_elb.master.zone_id}"
    evaluate_target_health = false
  }
}
