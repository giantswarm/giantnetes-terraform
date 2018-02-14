resource "aws_autoscaling_group" "worker" {
  name                = "${var.cluster_name}-worker"
  min_size            = 1
  max_size            = "${var.worker_count}"
  desired_capacity    = "${var.worker_count}"
  load_balancers      = ["${aws_elb.worker.id}"]
  vpc_zone_identifier = ["${var.worker_subnet_ids}"]

  health_check_type         = "EC2"
  health_check_grace_period = 300
  force_delete              = true
  metrics_granularity       = "1Minute"

  launch_configuration = "${aws_launch_configuration.worker.name}"

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "${var.cluster_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "KubernetesCluster"
    value               = "${var.cluster_name}"
    propagate_at_launch = true
  }
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
    device_name           = "/dev/xvdb"
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

  tags {
    Name              = "${var.cluster_name}-worker"
    Environment       = "${var.cluster_name}"
    KubernetesCluster = "${var.cluster_name}"
  }
}

# To avoid 16kb user_data limit upload CoreOS ignition config to a s3 bucket.
# Ignition supports s3 out-of-the-box.
resource "aws_s3_bucket_object" "ignition_worker" {
  bucket  = "${var.ignition_bucket_id}"
  key     = "${var.cluster_name}-ignition-worker.json"
  content = "${var.user_data}"
  acl     = "private"

  server_side_encryption = "AES256"

  tags = {
    Name        = "${var.cluster_name}-ignition-worker"
    Environment = "${var.cluster_name}"
  }
}

data "ignition_config" "s3" {
  replace {
    source       = "${format("s3://%s/%s", var.ignition_bucket_id, aws_s3_bucket_object.ignition_worker.key)}"
    verification = "sha512-${sha512(var.user_data)}"
  }
}
