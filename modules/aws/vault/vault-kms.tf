resource "aws_kms_key" "vault-unseal-key" {
  count                   = "${var.vault_auto_unseal ? 1 : 0}"
  description             = "${var.cluster_name} vault unseal key"
  deletion_window_in_days = 10

  tags = {
    Name                         = "${var.cluster_name}-vault-unseal-key"
    "giantswarm.io/installation" = "${var.cluster_name}"
  }
}

resource "aws_kms_alias" "vault-unseal-key" {
  count         = "${var.vault_auto_unseal ? 1 : 0}"
  name          = "alias/${var.cluster_name}-vault-unseal-key"
  target_key_id = "${aws_kms_key.vault-unseal-key[count.index].key_id}"
}
