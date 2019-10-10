provider "aws" {
  version = "~> 2.16.0"

  # Make sure to define profile in ~/.aws/config
  profile = "${var.cluster_name}"
}

locals {
  k8s_api_external_access_whitelist = "${var.external_ipsec_public_ip_0},${var.external_ipsec_public_ip_1}${var.k8s_api_external_access_whitelist != "" ? ",${var.k8s_api_external_access_whitelist}" : ""}"
}

module "container_linux" {
  source = "../../../modules/container-linux"

  coreos_channel = "${var.container_linux_channel}"
  coreos_version = "${var.container_linux_version}"
}

# Get ami ID for specific Container Linux version.
data "aws_ami" "coreos_ami" {
  owners = ["${var.ami_owner}"]

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
  subnets_bastion    = "${var.subnets_bastion}"
  subnets_elb        = "${var.subnets_elb}"
  subnets_worker     = "${var.subnets_worker}"
  subnets_vault      = "${var.subnets_vault}"
  vpc_cidr           = "${var.vpc_cidr}"
  with_public_access = "${var.aws_customer_gateway_id_0 == "" ? true : false}"
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
    "AWSRegion"                    = "${var.aws_region}"
    "BastionUsers"                 = "${file("${path.module}/../../../ignition/bastion-users.yaml")}"
    "BastionSubnet0"               = "${element(var.subnets_bastion, 0)}"
    "BastionSubnet1"               = "${element(var.subnets_bastion, 1)}"
    "BastionLogPriority"           = "${var.bastion_log_priority}"
    "BaseDomain"                   = "${var.base_domain}"
    "CalicoCIDR"                   = "${var.calico_cidr}"
    "CalicoMTU"                    = "${var.calico_mtu}"
    "CloudwatchForwarderEnabled"   = "${var.bastion_log_priority != "none" ? "true" : "false"}"
    "ClusterName"                  = "${var.cluster_name}"
    "DockerCIDR"                   = "${var.docker_cidr}"
    "DockerRegistry"               = "${var.docker_registry}"
    "ETCDEndpoints"                = "https://etcd1.${var.base_domain}:2379,https://etcd2.${var.base_domain}:2379,https://etcd3.${var.base_domain}:2379"
    "ETCDInitialClusterMulti"      = "etcd1=https://etcd1.${var.base_domain}:2380,etcd2=https://etcd2.${var.base_domain}:2380,etcd3=https://etcd3.${var.base_domain}:2380"
    "ETCDInitialClusterSingle"     = "etcd1=https://etcd1.${var.base_domain}:2380"
    "ExternalVpnGridscaleIp"       = "${var.external_ipsec_public_ip_0}"
    "ExternalVpnGridscalePassword" = "${var.external_ipsec_password}"
    "ExternalVpnGridscaleSubnet"   = "${var.external_ipsec_subnet_0}"
    "ExternalVpnGridscaleSourceIp" = "${cidrhost("${var.external_ipsec_subnet_0}", 1)}"
    "ExternalVpnVultrIp"           = "${var.external_ipsec_public_ip_1}"
    "ExternalVpnVultrPassword"     = "${var.external_ipsec_password}"
    "ExternalVpnVultrSubnet"       = "${var.external_ipsec_subnet_1}"
    "ExternalVpnVultrSourceIp"     = "${cidrhost("${var.external_ipsec_subnet_1}", 1)}"
    "G8SVaultToken"                = "${var.nodes_vault_token}"
    "ImagePullProgressDeadline"    = "${var.image_pull_progress_deadline}"
    "K8SAPIIP"                     = "${var.k8s_api_ip}"
    "K8SAPIExternalWhitelist"      = "${local.k8s_api_external_access_whitelist}"
    "K8SAuditWebhookPort"          = "${var.k8s_audit_webhook_port}"
    "K8SDNSIP"                     = "${var.k8s_dns_ip}"
    "K8SServiceCIDR"               = "${var.k8s_service_cidr}"
    "MasterCount"                  = "${var.master_count}"
    "MasterMountDocker"            = "${var.master_instance["volume_docker"]}"
    "MasterMountETCD"              = "${var.master_instance["volume_etcd"]}"
    "PodInfraImage"                = "${var.pod_infra_image}"
    "Provider"                     = "aws"
    "Users"                        = "${file("${path.module}/../../../ignition/users.yaml")}"
    "VaultDomainName"              = "${var.vault_dns}.${var.base_domain}"
    "WorkerMountDocker"            = "${var.worker_instance["volume_docker"]}"
  }
}

# Generate ignition config.
data "gotemplate" "bastion" {
  template = "${path.module}/../../../templates/bastion.yaml.tmpl"
  data     = "${jsonencode(merge(local.ignition_data, {"NodeType"="bastion"}))}"
  is_ignition = true
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
  user_data              = "${data.gotemplate.bastion.rendered}"
  with_public_access     = "${(var.aws_customer_gateway_id_0 != "") || (var.vpn_instance_enabled) ? false : true}"
  vpc_cidr               = "${var.vpc_cidr}"
  vpc_id                 = "${module.vpc.vpc_id}"
}

# Generate ignition config.
data "gotemplate" "vpn_instance" {
  template = "${path.module}/../../../templates/vpn.yaml.tmpl"
  data     = "${jsonencode(merge(local.ignition_data, {"NodeType"="vpn_instance"}))}"
  is_ignition = true
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
  external_vpn_cidr_0    = "${var.external_ipsec_public_ip_0}/32"
  external_vpn_cidr_1    = "${var.external_ipsec_public_ip_1}/32"
  ignition_bucket_id     = "${module.s3.ignition_bucket_id}"
  iam_region             = "${var.iam_region}"
  instance_type          = "${var.bastion_instance_type}"
  route53_enabled        = "${var.route53_enabled}"
  s3_bucket_tags         = "${var.s3_bucket_tags}"
  user_data              = "${data.gotemplate.vpn_instance.rendered}"
  vpc_cidr               = "${var.vpc_cidr}"
  vpc_id                 = "${module.vpc.vpc_id}"
}

# Generate ignition config.
data "gotemplate" "vault" {
  template = "${path.module}/../../../templates/vault.yaml.tmpl"
  data     = "${jsonencode(merge(local.ignition_data, {"NodeType"="vault"}))}"
  is_ignition = true
}

module "vault" {
  source = "../../../modules/aws/vault"

  arn_region             = "${var.arn_region}"
  aws_account            = "${var.aws_account}"
  aws_region             = "${var.aws_region}"
  cluster_name           = "${var.cluster_name}"
  container_linux_ami_id = "${data.aws_ami.coreos_ami.image_id}"
  dns_zone_id            = "${module.dns.public_dns_zone_id}"
  elb_subnet_ids         = "${module.vpc.elb_subnet_ids}"
  ignition_bucket_id     = "${module.s3.ignition_bucket_id}"
  iam_region             = "${var.iam_region}"
  instance_type          = "${var.vault_instance_type}"
  user_data              = "${data.gotemplate.vault.rendered}"
  route53_enabled        = "${var.route53_enabled}"
  s3_bucket_tags         = "${var.s3_bucket_tags}"
  vault_count            = "1"
  vault_dns              = "${var.vault_dns}"
  vault_subnet_ids       = "${module.vpc.vault_subnet_ids}"
  vpc_cidr               = "${var.vpc_cidr}"
  ipam_network_cidr      = "${var.ipam_network_cidr}"
  vpc_id                 = "${module.vpc.vpc_id}"
  worker_subnet_ids      = "${module.vpc.worker_subnet_ids}"
  worker_subnet_count    = length("${module.vpc.worker_subnet_ids}")
}

# Generate ignition config.
data "gotemplate" "master" {
  count = "${var.master_count}"

  template = "${path.module}/../../../templates/master.yaml.tmpl"
  data     = "${jsonencode(merge(local.ignition_data, {"NodeType"="master", "MasterID"="${count.index+1}", "ETCDDomainName"="etcd${count.index+1}.${var.base_domain}"}))}"
  is_ignition = true
}

module "master" {
  source = "../../../modules/aws/master"

  master_count = "${var.master_count}"

  api_dns                = "${var.api_dns}"
  aws_account            = "${var.aws_account}"
  cluster_name           = "${var.cluster_name}"
  container_linux_ami_id = "${data.aws_ami.coreos_ami.image_id}"
  dns_zone_id            = "${module.dns.public_dns_zone_id}"
  elb_subnet_ids         = "${module.vpc.elb_subnet_ids}"
  ignition_bucket_id     = "${module.s3.ignition_bucket_id}"
  instance_type          = "${var.master_instance["type"]}"
  route53_enabled        = "${var.route53_enabled}"
  user_data              = "${data.gotemplate.master.*.rendered}"
  master_subnet_ids      = "${module.vpc.worker_subnet_ids}"
  volume_docker          = "${var.master_instance["volume_docker"]}"
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
  data     = "${jsonencode(merge(local.ignition_data, {"NodeType"="worker"}))}"
  is_ignition = true
}

module "worker" {
  source = "../../../modules/aws/worker-asg"

  aws_account            = "${var.aws_account}"
  aws_region             = "${var.aws_region}"
  cluster_name           = "${var.cluster_name}"
  container_linux_ami_id = "${data.aws_ami.coreos_ami.image_id}"
  dns_zone_id            = "${module.dns.public_dns_zone_id}"
  elb_subnet_ids         = "${module.vpc.elb_subnet_ids}"
  ignition_bucket_id     = "${module.s3.ignition_bucket_id}"
  ingress_dns            = "${var.ingress_dns}"
  instance_type          = "${var.worker_instance["type"]}"
  route53_enabled        = "${var.route53_enabled}"
  user_data              = "${data.gotemplate.worker.rendered}"
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

terraform {
  required_version = ">= 0.12.6"

  backend "s3" {}
}
