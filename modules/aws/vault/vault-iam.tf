resource "aws_iam_role" "vault" {
  name = "${var.cluster_name}-vault"
  path = "/"

  lifecycle {
    create_before_destroy = true
  }

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "${var.iam_region}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "vault-kms-unseal" {
  statement {
    sid       = "VaultKMSUnseal"
    effect    = "Allow"
    resources = ["arn:${var.arn_region}:kms:${var.aws_region}:${var.aws_account}:key/${aws_kms_key.vault-unseal-key.id}"]

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
  }
}

resource "aws_iam_role_policy" "vault-kms-unseal" {
  name   = "${var.cluster_name}-vault-kms-unseal"
  role   = "${aws_iam_role.vault.id}"
  policy = "${data.aws_iam_policy_document.vault-kms-unseal.json}"
}

resource "aws_iam_instance_profile" "vault" {
  name = "${var.cluster_name}-vault"
  role = "${aws_iam_role.vault.name}"

  lifecycle {
    create_before_destroy = true
  }

  # Sleep a little to wait the IAM profile to be ready -
  provisioner "local-exec" {
    command = "sleep 10"
  }
}
