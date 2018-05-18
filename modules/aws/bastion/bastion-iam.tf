resource "aws_iam_role" "bastion" {
  name = "${var.cluster_name}-bastion"
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

resource "aws_iam_role_policy" "bastion" {
  name = "${var.cluster_name}-bastion"
  role = "${aws_iam_role.bastion.id}"

  lifecycle {
    create_before_destroy = true
  }

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:GetObject",
            "Resource": "arn:${var.arn_region}:s3:::${var.aws_account}-${var.cluster_name}-ignition/*"
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.cluster_name}-bastion"
  role = "${aws_iam_role.bastion.name}"

  lifecycle {
    create_before_destroy = true
  }

  # Sleep a little to wait the IAM profile to be ready -
  provisioner "local-exec" {
    command = "sleep 10"
  }
}
