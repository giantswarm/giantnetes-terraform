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
    values = ["${var.ami_owner}"]
  }
}

module "dns" {
  source = "../../../modules/aws/dns"

  cluster_name     = "${var.cluster_name}"
  root_dns_zone_id = "${var.root_dns_zone_id}"
  route53_enabled  = "${var.route53_enabled}"
  zone_name        = "${var.base_domain}"
}

module "vpc" {
  source = "../../../modules/aws/vpc"

  arn_region         = "${var.arn_region}"
  aws_account        = "${var.aws_account}"
  cluster_name       = "${var.cluster_name}"
  subnet_bastion_0   = "${var.subnet_bastion_0}"
  subnet_bastion_1   = "${var.subnet_bastion_1}"
  subnet_elb_0       = "${var.subnet_elb_0}"
  subnet_elb_1       = "${var.subnet_elb_1}"
  subnet_worker_0    = "${var.subnet_worker_0}"
  subnet_worker_1    = "${var.subnet_worker_1}"
  subnet_vault_0     = "${var.subnet_vault_0}"
  vpc_cidr           = "${var.vpc_cidr}"
  with_public_access = "${var.aws_customer_gateway_id_0 == "" ? 1 : 0 }"
}

# Create S3 bucket for ignition configs.
module "s3" {
  source = "../../../modules/aws/s3"

  aws_account          = "${var.aws_account}"
  cluster_name         = "${var.cluster_name}"
  logs_expiration_days = "${var.logs_expiration_days}"
}

locals {
  ignition_data = {
    "APIDomainName"                = "${var.api_dns}.${var.base_domain}"
    "BastionUsers"                 = "${file("${path.module}/../../../ignition/bastion-users.yaml")}"
    "BastionLogPriority"           = "${var.bastion_log_priority}"
    "CalicoCIDR"                   = "${var.calico_cidr}"
    "CloudwatchForwarderEnabled"   = "${var.bastion_log_priority != "none" ? "true" : "false" }"
    "ClusterName"                  = "${var.cluster_name}"
    "DockerCIDR"                   = "${var.docker_cidr}"
    "DockerRegistry"               = "${var.docker_registry}"
    "ETCDDomainName"               = "${var.etcd_dns}.${var.base_domain}"
    "ExternalVpnGridscaleIp"       = ""
    "ExternalVpnGridscalePassword" = ""
    "ExternalVpnGridscaleSubnet"   = ""
    "ExternalVpnGridscaleSourceIp" = ""
    "ExternalVpnVultrIp"           = ""
    "ExternalVpnVultrPassword"     = ""
    "ExternalVpnVultrSubnet"       = ""
    "ExternalVpnVultrSourceIp"     = ""
    "G8SVaultToken"                = "${var.nodes_vault_token}"
    "ImagePullProgressDeadline"    = "${var.image_pull_progress_deadline}"
    "K8SAPIIP"                     = "${var.k8s_api_ip}"
    "K8SDNSIP"                     = "${var.k8s_dns_ip}"
    "K8SServiceCIDR"               = "${var.k8s_service_cidr}"
    "MasterMountDocker"            = "${var.master_instance["mount_docker"]}"
    "MasterMountETCD"              = "${var.master_instance["mount_etcd"]}"
    "PodInfraImage"                = "${var.pod_infra_image}"
    "Provider"                     = "aws"
    "Users"                        = "${file("${path.module}/../../../ignition/users.yaml")}"
    "VaultDomainName"              = "${var.vault_dns}.${var.base_domain}"
    "WorkerMountDocker"            = "${var.worker_instance["mount_docker"]}"
  }
}

# Generate ignition config.
data "gotemplate" "bastion" {
  template = "${path.module}/../../../templates/bastion.yaml.tmpl"
  data     = "${jsonencode(local.ignition_data)}"
}

# Convert ignition config to raw json.
data "ct_config" "bastion" {
  content      = "${data.gotemplate.bastion.rendered}"
  platform     = "ec2"
  pretty_print = false
}

module "bastion" {
  source = "../../../modules/aws/bastion"

  arn_region             = "${var.arn_region}"
  aws_account            = "${var.aws_account}"
  bastion_count          = "2"
  bastion_subnet_ids     = "${module.vpc.bastion_subnet_ids}"
  cluster_name           = "${var.cluster_name}"
  container_linux_ami_id = "${data.aws_ami.coreos_ami.image_id}"
  dns_zone_id            = "${module.dns.public_dns_zone_id}"
  forward_logs_enabled   = "${var.bastion_forward_logs_enabled}"
  ignition_bucket_id     = "${module.s3.ignition_bucket_id}"
  iam_region             = "${var.iam_region}"
  instance_type          = "${var.bastion_instance_type}"
  route53_enabled        = "${var.route53_enabled}"
  s3_bucket_tags         = "${var.s3_bucket_tags}"
  user_data              = "${data.ct_config.bastion.rendered}"
  with_public_access     = "${var.aws_customer_gateway_id_0 == "" ? 1 : 0 }"
  vpc_cidr               = "${var.vpc_cidr}"
  vpc_id                 = "${module.vpc.vpc_id}"
}

# Generate ignition config.
data "gotemplate" "vpn_instance" {
  template = "${path.module}/../../../templates/vpn_instance.yaml.tmpl"
  data     = "${jsonencode(local.ignition_data)}"
}

# Convert ignition config to raw json.
data "ct_config" "vpn_instance" {
  content      = "${data.gotemplate.vpn_instance.rendered}"
  platform     = "ec2"
  pretty_print = false
}

module "vpn_instance" {
  source = "../../../modules/aws/vpn_instance"

  vpn_instance_enabled = "${var.vpn_instance_enabled}"

  arn_region             = "${var.arn_region}"
  aws_account            = "${var.aws_account}"
  bastion_subnet_ids     = "${module.vpc.bastion_subnet_ids}"
  cluster_name           = "${var.cluster_name}"
  container_linux_ami_id = "${data.aws_ami.coreos_ami.image_id}"
  dns_zone_id            = "${module.dns.public_dns_zone_id}"
  external_vpn_cidr_0    = "${var.external_vpn_cidr_0}"
  external_vpn_cidr_1    = "${var.external_vpn_cidr_1}"
  ignition_bucket_id     = "${module.s3.ignition_bucket_id}"
  iam_region             = "${var.iam_region}"
  instance_type          = "${var.bastion_instance_type}"
  route53_enabled        = "${var.route53_enabled}"
  s3_bucket_tags         = "${var.s3_bucket_tags}"
  user_data              = "${data.ct_config.vpn_instance.rendered}"
  vpc_cidr               = "${var.vpc_cidr}"
  vpc_id                 = "${module.vpc.vpc_id}"
}

# Generate ignition config.
data "gotemplate" "vault" {
  template = "${path.module}/../../../templates/vault.yaml.tmpl"
  data     = "${jsonencode(local.ignition_data)}"
}

# Convert ignition config to raw json.
data "ct_config" "vault" {
  content      = "${data.gotemplate.vault.rendered}"
  platform     = "ec2"
  pretty_print = false
}

module "vault" {
  source = "../../../modules/aws/vault"

  cluster_name           = "${var.cluster_name}"
  container_linux_ami_id = "${data.aws_ami.coreos_ami.image_id}"
  dns_zone_id            = "${module.dns.public_dns_zone_id}"
  elb_subnet_ids         = "${module.vpc.elb_subnet_ids}"
  instance_type          = "${var.vault_instance_type}"
  user_data              = "${data.ct_config.vault.rendered}"
  route53_enabled        = "${var.route53_enabled}"
  vault_count            = "1"
  vault_dns              = "${var.vault_dns}"
  vault_subnet_ids       = "${module.vpc.vault_subnet_ids}"
  vpc_cidr               = "${var.vpc_cidr}"
  ipam_network_cidr      = "${var.ipam_network_cidr}"
  vpc_id                 = "${module.vpc.vpc_id}"
  worker_subnet_ids      = "${module.vpc.worker_subnet_ids}"
}

# Generate ignition config.
data "gotemplate" "master" {
  template = "${path.module}/../../../templates/master.yaml.tmpl"
  data     = "${jsonencode(local.ignition_data)}"
}

# Convert ignition config to raw json.
data "ct_config" "master" {
  content      = "${data.gotemplate.master.rendered}"
  platform     = "ec2"
  pretty_print = false
}

module "master" {
  source = "../../../modules/aws/master"

  api_dns                = "${var.api_dns}"
  aws_account            = "${var.aws_account}"
  cluster_name           = "${var.cluster_name}"
  container_linux_ami_id = "${data.aws_ami.coreos_ami.image_id}"
  dns_zone_id            = "${module.dns.public_dns_zone_id}"
  elb_subnet_ids         = "${module.vpc.elb_subnet_ids}"
  etcd_dns               = "${var.etcd_dns}"
  ignition_bucket_id     = "${module.s3.ignition_bucket_id}"
  instance_type          = "${var.master_instance["type"]}"
  route53_enabled        = "${var.route53_enabled}"
  user_data              = "${data.ct_config.master.rendered}"
  master_subnet_ids      = "${module.vpc.worker_subnet_ids}"
  volume_etcd            = "${var.master_instance["volume_etcd"]}"
  vpc_cidr               = "${var.vpc_cidr}"
  vpc_id                 = "${module.vpc.vpc_id}"
  iam_region             = "${var.iam_region}"
  s3_bucket_tags         = "${var.s3_bucket_tags}"
  arn_region             = "${var.arn_region}"
}

# Generate ignition config.
data "gotemplate" "worker" {
  template = "${path.module}/../../../templates/worker.yaml.tmpl"
  data     = "${jsonencode(local.ignition_data)}"
}

# Convert ignition config to raw json.
data "ct_config" "worker" {
  content      = "${data.gotemplate.worker.rendered}"
  platform     = "ec2"
  pretty_print = false
}

module "worker" {
  source = "../../../modules/aws/worker-asg"

  aws_account            = "${var.aws_account}"
  cluster_name           = "${var.cluster_name}"
  container_linux_ami_id = "${data.aws_ami.coreos_ami.image_id}"
  dns_zone_id            = "${module.dns.public_dns_zone_id}"
  elb_subnet_ids         = "${module.vpc.elb_subnet_ids}"
  ignition_bucket_id     = "${module.s3.ignition_bucket_id}"
  ingress_dns            = "${var.ingress_dns}"
  instance_type          = "${var.worker_instance["type"]}"
  route53_enabled        = "${var.route53_enabled}"
  user_data              = "${data.ct_config.worker.rendered}"
  worker_count           = "${var.worker_count}"
  worker_subnet_ids      = "${module.vpc.worker_subnet_ids}"
  volume_docker          = "${var.worker_instance["volume_docker"]}"
  vpc_cidr               = "${var.vpc_cidr}"
  vpc_id                 = "${module.vpc.vpc_id}"
  iam_region             = "${var.iam_region}"
  s3_bucket_tags         = "${var.s3_bucket_tags}"
  arn_region             = "${var.arn_region}"
}

module "vpn" {
  source = "../../../modules/aws/vpn"

  # If aws_customer_gateway_id_0 is not set, no vpn resources will be created.
  aws_customer_gateway_id_0   = "${var.aws_customer_gateway_id_0}"
  aws_customer_gateway_id_1   = "${var.aws_customer_gateway_id_1}"
  aws_cluster_name            = "${var.cluster_name}"
  aws_external_ipsec_subnet_0 = "${var.external_ipsec_subnet_0}"
  aws_external_ipsec_subnet_1 = "${var.external_ipsec_subnet_1}"
  aws_private_route_table_ids = "${module.vpc.private_route_table_ids}"
  aws_vpn_name                = "Giant Swarm <-> ${var.cluster_name}"
  aws_vpn_vpc_id              = "${module.vpc.vpc_id}"
}
