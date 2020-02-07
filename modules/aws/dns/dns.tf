resource "aws_route53_zone" "public" {
  count   = var.route53_enabled ? 1 : 0
  comment = "{\"last_updated\":\"${timestamp()}\",\"managed_by\":\"terraform\"}"
  name    = var.zone_name

  tags = {
    Name                         = "${var.zone_name}"
    "giantswarm.io/installation" = "${var.cluster_name}"
  }

  lifecycle {
    ignore_changes = [comment]
  }
}

resource "aws_route53_zone" "private" {
  count   = var.route53_enabled ? 1 : 0
  comment = "{\"last_updated\":\"${timestamp()}\",\"managed_by\":\"terraform\"}"
  name = var.zone_name

  vpc {
    vpc_id = var.vpc_id
  }

  tags = {
    Name                         = "${var.zone_name}"
    "giantswarm.io/installation" = "${var.cluster_name}"
  }

  lifecycle {
    ignore_changes = [comment]
  }
}

resource "aws_route53_record" "delegation" {
  count   = var.root_dns_zone_id == "" ? 0 : 1
  zone_id = var.root_dns_zone_id
  name    = var.zone_name
  type    = "NS"
  ttl     = "300"
  records = aws_route53_zone.public[count.index].name_servers
}

output "public_dns_zone_id" {
  value = join(" ", aws_route53_zone.public.*.id)
}
