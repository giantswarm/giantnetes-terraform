locals {
  common_tags = "${map(
    "giantswarm.io/installation", "${var.cluster_name}",
    "kubernetes.io/cluster/${var.cluster_name}", "owned"
  )}"
}

resource "aws_cloudformation_stack" "worker_asg" {
  name = "${var.cluster_name}-worker"

  template_body = <<EOF
{
  "Resources": {
    "AutoScalingGroup": {
      "Type": "AWS::AutoScaling::AutoScalingGroup",
      "Properties": {
        "DesiredCapacity": "${var.worker_count}",
        "HealthCheckType": "EC2",
        "HealthCheckGracePeriod": 300,
        "LaunchConfigurationName": "${aws_launch_configuration.worker.name}",
        "LoadBalancerNames": [
          "${var.cluster_name}-worker"
        ],
        "MaxSize": "${var.worker_count}",
        "MinSize": "1",
        "Tags": [
          {
            "Key": "Name",
            "Value": "${var.cluster_name}-worker",
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
          }
        ],
        "VPCZoneIdentifier": ${jsonencode(var.worker_subnet_ids)}
      },
      "UpdatePolicy": {
        "AutoScalingRollingUpdate": {
          "MinInstancesInService": "${var.worker_count - 1}",
          "MaxBatchSize": "1",
          "PauseTime": "PT5M"
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

resource "aws_launch_configuration" "worker" {
  name_prefix          = "${var.cluster_name}-worker-"
  iam_instance_profile = "${aws_iam_instance_profile.worker.name}"
  image_id             = "${var.container_linux_ami_id}"
  instance_type        = "${var.instance_type}"
  security_groups      = ["${aws_security_group.worker.id}"]

  lifecycle {
    create_before_destroy = true
  }

  associate_public_ip_address = false

  root_block_device = {
    volume_type = "${var.volume_type}"
    volume_size = "${var.volume_size_root}"
  }

  # Docker volume.
  ebs_block_device = {
    device_name           = "${var.volume_device_name_docker}"
    delete_on_termination = true
    volume_type           = "${var.volume_type}"
    volume_size           = "${var.volume_size_docker}"
  }

  user_data = "${data.ignition_config.s3.rendered}"
}

resource "aws_security_group" "worker" {
  name   = "${var.cluster_name}-worker"
  vpc_id = "${var.vpc_id}"

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
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  # Allow access from vpc
  ingress {
    from_port   = 10
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  # Allow IPIP traffic from vpc
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = 4
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-worker"
    )
  )}"
}

# To avoid 16kb user_data limit upload CoreOS ignition config to a s3 bucket.
# Ignition supports s3 out-of-the-box.
resource "aws_s3_bucket_object" "ignition_worker" {
  bucket  = "${var.ignition_bucket_id}"
  key     = "${var.cluster_name}-ignition-worker.json"
  content = "${var.user_data}"
  acl     = "private"

  server_side_encryption = "AES256"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-ignition-worker"
    )
  )}"
}

data "ignition_config" "s3" {
  replace {
    source       = "${format("s3://%s/%s", var.ignition_bucket_id, aws_s3_bucket_object.ignition_worker.key)}"
    verification = "sha512-${sha512(var.user_data)}"
  }
}
