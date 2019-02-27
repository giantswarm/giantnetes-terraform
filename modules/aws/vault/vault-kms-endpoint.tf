resource "aws_vpc_endpoint" "kms" {
  count         = "${var.vault_count}"
  vpc_id       = "${var.vpc_id}"
  service_name = "com.amazonaws.${var.aws_region}.kms"
  vpc_endpoint_type = "Interface"

  security_group_ids = ["${aws_security_group.vault.id}"]
  subnet_ids          = ["${var.vault_subnet_ids[count.index]}"]
}


