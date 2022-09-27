locals {
  # In China there is no tags for s3 buckets
  s3_ignition_worker_key = element(concat(aws_s3_bucket_object.ignition_worker_with_tags.*.key, aws_s3_bucket_object.ignition_worker_without_tags.*.key), 0)

  common_tags = merge(
    var.additional_tags,
    map(
      "giantswarm.io/cluster", var.cluster_name,
      "giantswarm.io/installation", var.cluster_name,
      "kubernetes.io/cluster/${var.cluster_name}", "owned"
    )
  )
  common_tags_asg = join("",[for key, value in var.additional_tags : "{\"Key\":\"${key}\",\"Value\":\"${value}\",\"PropagateAtLaunch\": true},"])


}

resource "aws_cloudformation_stack" "worker_asg_single_az" {
  count = length(var.worker_subnet_ids)
  name = "${var.cluster_name}-worker-${count.index}"

  template_body = <<EOF
{
  "Resources": {
    "AutoScalingGroup": {
      "Type": "AWS::AutoScaling::AutoScalingGroup",
      "Properties": {
        "DesiredCapacity": "2",
        "HealthCheckType": "EC2",
        "HealthCheckGracePeriod": 300,
        "LaunchConfigurationName": "${aws_launch_configuration.worker_asg_single_az.name}",
        "LifecycleHookSpecificationList": [
          {
            "DefaultResult" : "CONTINUE",
            "HeartbeatTimeout" : 900,
            "LifecycleHookName" : "${var.cluster_name}-lifecycle-hook",
            "LifecycleTransition" : "autoscaling:EC2_INSTANCE_TERMINATING",
            "NotificationTargetARN" : "${var.sqs_temination_queue_arn}",
            "RoleARN" : "${aws_iam_role.worker_lifecycle_hooks.arn}"
          }
        ],
        "LoadBalancerNames": [
          "${var.cluster_name}-worker"
        ],
        "MaxSize": "${var.worker_count * 2}",
        "MinSize": "1",
        "Tags": [
          ${local.common_tags_asg}
          {
            "Key": "Name",
            "Value": "${var.cluster_name}-worker",
            "PropagateAtLaunch": true
          },
          {
            "Key": "giantswarm.io/cluster",
            "Value": "${var.cluster_name}",
            "PropagateAtLaunch": true
          },
          {
            "Key": "giantswarm.io/installation",
            "Value": "${var.cluster_name}",
            "PropagateAtLaunch": true
          },
          {
            "Key": "kubernetes.io/cluster/${var.cluster_name}",
            "Value": "owned",
            "PropagateAtLaunch": true
          },
          {
            "Key": "k8s.io/cluster-autoscaler/enabled",
            "Value": "true",
            "PropagateAtLaunch": false
          },
          {
            "Key": "k8s.io/cluster-autoscaler/${var.cluster_name}",
            "Value": "true",
            "PropagateAtLaunch": false
          },
                    {
            "Key": "aws-node-termination-handler/managed",
            "Value": "",
            "PropagateAtLaunch": true
          }
        ],
        "VPCZoneIdentifier": [${jsonencode(element(var.worker_subnet_ids, count.index))}]
      },
      "UpdatePolicy": {
        "AutoScalingRollingUpdate": {
          "MinInstancesInService": "1",
          "MaxBatchSize": "1",
          "PauseTime": "PT3M"
        }
      }
    }
  },
  "Outputs": {
    "AsgName": {
      "Description": "The name of the auto scaling group",
      "Value": {
        "Ref": "AutoScalingGroup"
      }
    }
  }
}
EOF
}

resource "aws_launch_configuration" "worker_asg_single_az" {
  name_prefix          = "${var.cluster_name}-worker-singleaz-"
  iam_instance_profile = aws_iam_instance_profile.worker.name
  image_id             = var.container_linux_ami_id
  instance_type        = var.instance_type
  security_groups      = [aws_security_group.worker.id]

  lifecycle {
    create_before_destroy = true
  }

  associate_public_ip_address = false

  root_block_device {
    volume_type = var.volume_type
    volume_size = var.volume_size_root
  }

  # Docker volume.
  ebs_block_device {
    device_name           = var.volume_docker
    delete_on_termination = true
    volume_type           = var.volume_type
    volume_size           = var.volume_size_docker
  }

  metadata_options {
    http_endpoint = "enabled"
    http_put_response_hop_limit = 5
  }

  user_data = data.ignition_config.s3.rendered
}

resource "aws_security_group" "worker" {
  name   = "${var.cluster_name}-worker"
  vpc_id = var.vpc_id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow access from vpc
  ingress {
    from_port   = 10
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr, var.aws_cni_cidr_block]
  }

  # Allow access from vpc
  ingress {
    from_port   = 10
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr, var.aws_cni_cidr_block]
  }

  # Allow IPIP traffic from vpc
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = 4
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-worker"
    )
  )
}

# To avoid 16kb user_data limit upload CoreOS ignition config to a s3 bucket.
# Ignition supports s3 out-of-the-box.
resource "aws_s3_bucket_object" "ignition_worker_with_tags" {
  count   = var.s3_bucket_tags ? 1 : 0
  bucket  = var.ignition_bucket_id
  key     = "${var.cluster_name}-ignition-worker.json"
  content = var.user_data
  acl     = "private"

  server_side_encryption = "AES256"

  tags = merge(
    var.additional_tags,
    map(
      "Name", "${var.cluster_name}-ignition-worker"
    )
  )
}

# To avoid 16kb user_data limit upload CoreOS ignition config to a s3 bucket.
# Ignition supports s3 out-of-the-box.
resource "aws_s3_bucket_object" "ignition_worker_without_tags" {
  count   = var.s3_bucket_tags ? 0 : 1
  bucket  = var.ignition_bucket_id
  key     = "${var.cluster_name}-ignition-worker.json"
  content = var.user_data
  acl     = "private"

  server_side_encryption = "AES256"
}

data "ignition_config" "s3" {
  replace {
    source       = format("s3://%s/%s", var.ignition_bucket_id, local.s3_ignition_worker_key)
    verification = "sha512-${sha512(var.user_data)}"
  }
}
