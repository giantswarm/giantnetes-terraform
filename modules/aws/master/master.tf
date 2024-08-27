locals {
  common_tags = merge(
    var.additional_tags,
    tomap({
      "giantswarm.io/cluster" = var.cluster_name
      "giantswarm.io/installation" = var.cluster_name
      "giantswarm.io/cluster-type" = "control-plane"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    })
  )

  common_tags_asg = join("",[for key, value in var.additional_tags : "{\"Key\":\"${key}\",\"Value\":\"${value}\",\"PropagateAtLaunch\": true},"])

  customer_vpn_public_subnets = var.customer_vpn_public_subnets != "" ? split(",", var.customer_vpn_public_subnets) : []
  customer_vpn_private_subnets = var.customer_vpn_private_subnets != "" ? split(",", var.customer_vpn_private_subnets) : []
  # k8s_api prefixed values represent access to public loadbalancer
  k8s_api_internal_access_whitelist = concat([var.aws_cni_cidr_block,var.vpc_cidr], var.nat_gateway_public_ips)
  k8s_api_external_access_whitelist = concat(["${var.external_ipsec_public_ip_0}/32", "${var.external_ipsec_public_ip_1}/32"], local.customer_vpn_public_subnets)
  # k8s_api_internal prefixed values represent access to private loadbalancer
  k8s_api_internal_internal_access_whitelist = concat([var.aws_cni_cidr_block,var.vpc_cidr], var.nat_gateway_public_ips)
  k8s_api_internal_external_access_whitelist = concat(["${var.external_ipsec_public_ip_0}/32", "${var.external_ipsec_public_ip_1}/32"], local.customer_vpn_private_subnets)
}

data "aws_availability_zones" "available" {}


resource "aws_cloudformation_stack" "master_asg" {
  count = var.master_count
  name  = "${var.cluster_name}-master-${count.index}"

  template_body = <<EOF
{
  "Resources": {
    "AutoScalingGroup": {
      "Type": "AWS::AutoScaling::AutoScalingGroup",
      "Properties": {
        "DesiredCapacity": "1",
        "HealthCheckType": "EC2",
        "HealthCheckGracePeriod": 300,
        "LaunchConfigurationName": "${element(aws_launch_configuration.master.*.name, count.index)}",
        "LifecycleHookSpecificationList": [
          {
            "DefaultResult" : "CONTINUE",
            "HeartbeatTimeout" : 900,
            "LifecycleHookName" : "${var.cluster_name}-lifecycle-hook",
            "LifecycleTransition" : "autoscaling:EC2_INSTANCE_TERMINATING",
            "NotificationTargetARN" : "${var.sqs_temination_queue_arn}",
            "RoleARN" : "${aws_iam_role.master_lifecycle_hooks.arn}"
          }
        ],
        "LoadBalancerNames": [
          "${var.cluster_name}-master-api",
          "${var.cluster_name}-master-api-internal",
          "${var.cluster_name}-worker"
        ],
        "MaxSize": "1",
        "DesiredCapacity": "1",
        "MinSize": "1",
        "Tags": [
          ${local.common_tags_asg}
          {
            "Key": "Name",
            "Value": "${var.cluster_name}-master-${count.index}",
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
            "Key": "aws-node-termination-handler/managed",
            "Value": "",
            "PropagateAtLaunch": true
          }
        ],
        "VPCZoneIdentifier": ["${var.master_subnet_ids[count.index]}"]
      },
      "UpdatePolicy": {
        "AutoScalingRollingUpdate": {
          "MinInstancesInService": "0",
          "MaxBatchSize": "1",
          "PauseTime": "PT2M"
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

  depends_on = [
    aws_elb.master_api,
    aws_elb.master_api_internal,
  ]
}

resource "aws_launch_configuration" "master" {
  count                = var.master_count
  name_prefix          = "${var.cluster_name}-master-"
  iam_instance_profile = element(aws_iam_instance_profile.master.*.name, count.index)
  image_id             = var.container_linux_ami_id
  instance_type        = var.instance_type
  security_groups      = [aws_security_group.master.id]

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

  user_data = element(data.ignition_config.s3.*.rendered, count.index)
}

resource "aws_ebs_volume" "master_etcd" {
  count = var.master_count

  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  size              = var.volume_size_etcd
  type              = var.volume_type

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "${var.cluster_name}-master${count.index + 1}-etcd"
    })
  )
}

resource "aws_security_group" "master" {
  name   = "${var.cluster_name}-master"
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
    tomap({
      "Name" = "${var.cluster_name}-master"
    })
  )
}

resource "aws_route53_record" "master" {
  count   = var.master_count
  zone_id = var.dns_zone_id
  name    = "master${count.index + 1}"
  type    = "A"
  records = [element(var.master_eni_ips, count.index)]
  ttl     = "30"
}

resource "aws_route53_record" "etcd" {
  count   = var.master_count
  zone_id = var.dns_zone_id
  name    = "etcd${count.index + 1}"
  type    = "A"
  records = [element(var.master_eni_ips, count.index)]
  ttl     = "30"
}

resource "aws_network_interface" "master" {
  count           = var.master_count
  subnet_id       = element(var.master_subnet_ids, count.index)
  private_ips     = [element(var.master_eni_ips, count.index)]
  security_groups = [aws_security_group.master.id]

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "${var.cluster_name}-master${count.index + 1}-etcd"
      "node.k8s.amazonaws.com/no_manage" = "true"
    })
  )

  lifecycle {
    ignore_changes = [
      # ignore changes on the private IP list
      private_ips,
    ]
  }

}

# To avoid 16kb user_data limit upload CoreOS ignition config to a s3 bucket.
# Ignition supports s3 out-of-the-box.
resource "aws_s3_bucket_object" "ignition_master_with_tags" {
  count   = var.s3_bucket_tags ? var.master_count : 0
  bucket  = var.ignition_bucket_id
  key     = "${var.cluster_name}-ignition-master${count.index + 1}.json"
  content = var.user_data[count.index]
  acl     = "private"

  server_side_encryption = "AES256"

  tags = merge(
    var.additional_tags,
    tomap({
      "Name" = "${var.cluster_name}-ignition-master"
    })
  )
}

# To avoid 16kb user_data limit upload CoreOS ignition config to a s3 bucket.
# Ignition supports s3 out-of-the-box.
resource "aws_s3_bucket_object" "ignition_master_without_tags" {
  count   = var.s3_bucket_tags ? 0 : var.master_count
  bucket  = var.ignition_bucket_id
  key     = "${var.cluster_name}-ignition-master${count.index + 1}.json"
  content = var.user_data[count.index]
  acl     = "private"

  server_side_encryption = "AES256"
}

locals {
  # In China there is no tags for s3 buckets
  s3_ignition_master_keys = concat(aws_s3_bucket_object.ignition_master_with_tags.*.key, aws_s3_bucket_object.ignition_master_without_tags.*.key)
}

data "ignition_config" "s3" {
  count = var.master_count

  replace {
    source       = format("s3://%s/%s", var.ignition_bucket_id, element(local.s3_ignition_master_keys, count.index))
    verification = "sha512-${sha512(var.user_data[count.index])}"
  }
}
