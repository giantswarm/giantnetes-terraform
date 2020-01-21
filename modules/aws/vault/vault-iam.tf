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

resource "aws_iam_role_policy" "vault-s3-ignition" {
  name = "${var.cluster_name}-vault-s3-ignition"
  role = aws_iam_role.vault.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:${var.arn_region}:s3:::${var.aws_account}-${var.cluster_name}-ignition/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "vault" {
  name = "${var.cluster_name}-vault"
  role = aws_iam_role.vault.name

  lifecycle {
    create_before_destroy = true
  }
}
