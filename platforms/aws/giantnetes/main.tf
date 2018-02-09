module "container_linux" {
  source = "../../../modules/container-linux"

  coreos_channel = "${var.container_linux_channel}"
  coreos_version = "${var.container_linux_version}"
}

# Get ami ID for specific Container Linux version.
data "aws_ami" "coreos_ami" {
  filter {
    name   = "name"
    values = ["CoreOS-${var.container_linux_channel}-${module.container_linux.coreos_version}-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "owner-id"
    values = ["595879546273"]
  }
}

module "dns" {
  source = "../../../modules/aws/dns"

  cluster_name     = "${var.cluster_name}"
  root_dns_zone_id = "${var.root_dns_zone_id}"
  zone_name        = "${var.base_domain}"
}

module "vpc" {
  source = "../../../modules/aws/vpc"

  cluster_name     = "${var.cluster_name}"
  subnet_bastion_0 = "${var.subnet_bastion_0}"
  subnet_bastion_1 = "${var.subnet_bastion_1}"
  subnet_elb_0     = "${var.subnet_elb_0}"
  subnet_elb_1     = "${var.subnet_elb_1}"
  subnet_worker_0  = "${var.subnet_worker_0}"
  subnet_worker_1  = "${var.subnet_worker_1}"
  subnet_vault_0   = "${var.subnet_vault_0}"
  vpc_cidr         = "${var.vpc_cidr}"
}

# Create S3 bucket for ignition configs.
module "s3" {
  source = "../../../modules/aws/s3"

  aws_account  = "${var.aws_account}"
  cluster_name = "${var.cluster_name}"
}

locals {
  ignition_users = "${file("${path.module}/../../../ignition/users.yaml")}"
}

# Generate ignition config for bastions.
data "template_file" "bastion" {
  template = "${file("${path.module}/../../../ignition/bastion.yaml.tmpl")}"
}

# Convert ignition config to raw json.
data "ct_config" "bastion" {
  content      = "${format("%s\n%s", local.ignition_users, data.template_file.bastion.rendered)}"
  platform     = "ec2"
  pretty_print = false
}

module "bastion" {
  source = "../../../modules/aws/bastion"

  bastion_count          = "2"
  bastion_subnet_ids     = "${module.vpc.bastion_subnet_ids}"
  aws_account            = "${var.aws_account}"
  cluster_name           = "${var.cluster_name}"
  container_linux_ami_id = "${data.aws_ami.coreos_ami.image_id}"
  dns_zone_id            = "${module.dns.public_dns_zone_id}"
  instance_type          = "${var.bastion_instance_type}"
  user_data              = "${data.ct_config.bastion.rendered}"
  with_public_access     = true
  vpc_cidr               = "${var.vpc_cidr}"
  vpc_id                 = "${module.vpc.vpc_id}"
}
