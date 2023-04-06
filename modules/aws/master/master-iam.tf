resource "aws_iam_role" "master" {
  name = "${var.cluster_name}-master"
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

resource "aws_iam_role_policy" "master" {
  name = "${var.cluster_name}-master"
  role = aws_iam_role.master.id

  lifecycle {
    create_before_destroy = true
  }

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "elasticloadbalancing:*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:${var.arn_region}:s3:::${var.aws_account}-${var.cluster_name}-ignition/*"
      ]
    },
    {
     "Effect": "Allow",
     "Action": [
       "logs:*",
       "s3:GetObject"
     ],
     "Resource": [
       "arn:${var.arn_region}:logs:${var.aws_region}:*:*",
       "arn:${var.arn_region}:s3:::*"
     ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:ListBucket",
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject" 
        ],
        "Resource": [
            "arn:${var.arn_region}:s3:::${var.cluster_name}-g8s-mimir",
            "arn:${var.arn_region}:s3:::${var.cluster_name}-g8s-mimir/*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
          "ec2:AssignPrivateIpAddresses",
          "ec2:AttachNetworkInterface",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeTags",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DetachNetworkInterface",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:UnassignPrivateIpAddresses"
        ],
        "Resource": "*"
      },
      {
         "Effect": "Allow",
         "Action": [
            "ec2:CreateTags"
          ],
          "Resource": ["arn:${var.arn_region}:ec2:*:*:network-interface/*"]
      },
      {
        "Action": [
           "autoscaling:DescribeAutoScalingGroups",
           "autoscaling:DescribeAutoScalingInstances",
           "autoscaling:DescribeLaunchConfigurations",
           "autoscaling:DescribeTags",
           "ec2:DescribeLaunchTemplateVersions"
        ],
        "Resource": "*",
        "Effect": "Allow"
      },
      {
        "Action": [
           "autoscaling:SetDesiredCapacity",
           "autoscaling:TerminateInstanceInAutoScalingGroup"
        ],
        "Resource": "arn:${var.arn_region}:autoscaling:${var.aws_region}:${var.aws_account}:autoScalingGroup:*:autoScalingGroupName/${var.cluster_name}-worker-*",
        "Effect": "Allow"
      },
      {
        "Effect": "Allow",
        "Action": [
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeTags",
          "ec2:DescribeInstances",
          "sqs:DeleteMessage",
          "sqs:ReceiveMessage"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ],
        "Resource": [
          "*"
        ],
        "Condition": {
          "Bool": {
            "kms:GrantIsForAWSResource": "true"
          }
        }
      },
      {
        "Effect": "Allow",
        "Action": [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource": [
          "*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "autoscaling:SetInstanceHealth"
        ],
        "Resource": [
          "arn:${var.arn_region}:autoscaling:${var.aws_region}:${var.aws_account}:autoScalingGroup:*:autoScalingGroupName/${var.cluster_name}-master-*"
        ]
      }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "master" {
  name = "${var.cluster_name}-master"
  role = aws_iam_role.master.name

  lifecycle {
    create_before_destroy = true
  }

  # Sleep a little to wait the IAM profile to be ready -
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource "aws_iam_role" "master_lifecycle_hooks" {
  name = "${var.cluster_name}-master-lifecycle-hooks"
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
        "Service": "autoscaling.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "master_lifecycle_hooks" {
  name = "${var.cluster_name}-master-lifecycle-hooks"
  role = aws_iam_role.master_lifecycle_hooks.id

  lifecycle {
    create_before_destroy = true
  }

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage",
        "sqs:GetQueueUrl"
      ],
      "Resource": [
        "${var.sqs_temination_queue_arn}"
      ]
    }
  ]
}
EOF
}
