resource "aws_elb" "master_api" {
  name                      = "${var.cluster_name}-master-api"
  cross_zone_load_balancing = true
  idle_timeout              = 3600
  internal                  = false
  subnets                   = var.elb_subnet_ids
  security_groups           = [aws_security_group.master_elb_api.id]

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
    tomap({
      "Name" = "${var.cluster_name}-master-api"
    })
  )
}

resource "aws_elb" "master_api_internal" {
  name                      = "${var.cluster_name}-master-api-internal"
  cross_zone_load_balancing = true
  idle_timeout              = 3600
  internal                  = true
  subnets                   = var.elb_subnet_ids
  security_groups           = [aws_security_group.master_elb_api_internal.id]

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
    tomap({
      "Name" = "${var.cluster_name}-master-api-internal"
    })
  )
}

resource "aws_security_group" "master_elb_api" {
  name   = "${var.cluster_name}-master-elb-api"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # internal access
  # if list containst single IP - add /32
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      for ip in local.k8s_api_internal_access_whitelist:
      length(regexall(".*\\/.*", ip)) == 1 ? ip : format("%s/32", ip)
    ]
  }

  # extrenal access
  # if list containst single IP - add /32
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      for ip in local.k8s_api_external_access_whitelist:
      length(regexall(".*\\/.*", ip)) == 1 ? ip : format("%s/32", ip)
    ]
  }

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "${var.cluster_name}-master-elb-api"
    })
  )
}

resource "aws_security_group" "master_elb_api_internal" {
  name   = "${var.cluster_name}-master-elb-api-internal"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # internal access
  # if list containst single IP - add /32
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      for ip in local.k8s_api_internal_internal_access_whitelist:
      length(regexall(".*\\/.*", ip)) == 1 ? ip : format("%s/32", ip)
    ]
  }

  # extrenal access
  # if list containst single IP - add /32
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      for ip in local.k8s_api_internal_external_access_whitelist:
      length(regexall(".*\\/.*", ip)) == 1 ? ip : format("%s/32", ip)
    ]
  }

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "${var.cluster_name}-master-elb-api-internal"
    })
  )
}

resource "aws_route53_record" "master_api" {
  zone_id = var.dns_zone_id
  name    = var.api_dns
  type    = "A"

  alias {
    name                   = aws_elb.master_api.dns_name
    zone_id                = aws_elb.master_api.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "master_api_internal" {
  zone_id = var.dns_zone_id
  name    = var.api_internal_dns
  type    = "A"

  alias {
    name                   = aws_elb.master_api_internal.dns_name
    zone_id                = aws_elb.master_api.zone_id
    evaluate_target_health = false
  }
}
