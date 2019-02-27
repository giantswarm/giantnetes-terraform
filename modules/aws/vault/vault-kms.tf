resource "aws_kms_key" "vault-unseal-key" {
  description             = "${var.cluster_name} vault unseal key"
  deletion_window_in_days = 10

  tags = {
    Name                         = "${var.cluster_name}-vault-unseal-key"
    "giantswarm.io/installation" = "${var.cluster_name}"
  }
}

resource "aws_kms_alias" "vault-unseal-key" {
  name          = "alias/${var.cluster_name}-vault-unseal-key"
  target_key_id = "${aws_kms_key.vault-unseal-key.key_id}"
}
