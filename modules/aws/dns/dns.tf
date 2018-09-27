variable "cluster_name" {
  type = "string"
}

variable "root_dns_zone_id" {
  type = "string"
}

variable "route53_enabled" {
  default = true
}

variable "zone_name" {
  type = "string"
}

resource "aws_route53_zone" "public" {
  count = "${var.route53_enabled ? 1 : 0}"
  name  = "${var.zone_name}"

  tags {
    Name                         = "${var.zone_name}"
    "giantswarm.io/installation" = "${var.cluster_name}"
  }
}

resource "aws_route53_record" "delegation" {
  count   = "${var.root_dns_zone_id == "" ? 0 : 1}"
  zone_id = "${var.root_dns_zone_id}"
  name    = "${var.zone_name}"
  type    = "NS"
  ttl     = "300"
  records = ["${aws_route53_zone.public.name_servers}"]
}

output "public_dns_zone_id" {
  value = "${ join(" ", aws_route53_zone.public.*.id) }"
}
