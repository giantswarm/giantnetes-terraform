resource "aws_iam_role" "worker" {
  name = "${var.cluster_name}-worker"
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

resource "aws_iam_role_policy" "worker" {
  name = "${var.cluster_name}-worker"
  role = aws_iam_role.worker.id

  lifecycle {
    create_before_destroy = true
  }

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:Describe*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ec2:AttachVolume",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ec2:CreateVolume",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ec2:DetachVolume",
      "Resource": "*"
    },
    {
     "Effect": "Allow",
     "Action": "ec2:CreateTags",
      "Resource": "*"
    },
    {
      "Action": "elasticloadbalancing:*",
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action" : [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances"
      ],
      "Resource": "*",
      "Effect": "Allow"
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
            "arn:${var.arn_region}:s3:::${var.cluster_name}-g8s-loki",
            "arn:${var.arn_region}:s3:::${var.cluster_name}-g8s-loki/*"
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
            "s3:ListBucket",
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject" 
        ],
        "Resource": [
            "arn:${var.arn_region}:s3:::${var.cluster_name}-g8s-mimir-ruler",
            "arn:${var.arn_region}:s3:::${var.cluster_name}-g8s-mimir-ruler/*"
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
            "arn:${var.arn_region}:s3:::${var.cluster_name}-g8s-tempo",
            "arn:${var.arn_region}:s3:::${var.cluster_name}-g8s-tempo/*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:GetAccessPoint",
            "s3:GetAccountPublicAccessBlock",
            "s3:ListAccessPoints"
        ],
        "Resource": "*"
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
      }

  ]
}
EOF
}

resource "aws_iam_instance_profile" "worker" {
  name = "${var.cluster_name}-worker"
  role = aws_iam_role.worker.name

  lifecycle {
    create_before_destroy = true
  }

  # Sleep a little to wait the IAM profile to be ready -
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource "aws_iam_role" "worker_lifecycle_hooks" {
  name = "${var.cluster_name}-worker-lifecycle-hooks"
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

resource "aws_iam_role_policy" "worker_lifecycle_hooks" {
  name = "${var.cluster_name}-worker-lifecycle-hooks"
  role = aws_iam_role.worker_lifecycle_hooks.id

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
