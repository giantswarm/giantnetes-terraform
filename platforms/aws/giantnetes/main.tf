provider "aws" {
  # Make sure to define profile in ~/.aws/config
  profile = var.cluster_name
  region  = var.aws_region
}

locals {
  # VPC subnet has reserved first 4 IPs so we need to use the fifth one (counting from zero it is index 4)
  # https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html
  masters_eni_ips         = [cidrhost(var.subnets_worker[0], 4), cidrhost(var.subnets_worker[1], 4), cidrhost(var.subnets_worker[2], 4)]
  masters_eni_gateways    = [cidrhost(var.subnets_worker[0], 1), cidrhost(var.subnets_worker[1], 1), cidrhost(var.subnets_worker[2], 1)]
  masters_eni_subnet_size = split("/", var.subnets_worker[0])[1]

  additional_tags_ignition = join(" ", [for key, value in var.additional_tags : "Key=${key},Value=${value}"])
}

data "http" "bastion_users" {
  url = "https://api.github.com/repos/giantswarm/employees/contents/employees.yaml?ref=${var.employees_branch}"

  # Optional request headers
  request_headers = {
    Authorization = "token ${var.github_token}"
  }
}

module "flatcar_linux" {
  source = "../../../modules/flatcar-linux"

  aws_region = var.aws_region

  flatcar_channel = var.flatcar_linux_channel
  flatcar_version = var.flatcar_linux_version
}

data "aws_availability_zones" "available" {}

# Get ami ID for specific Flatcar Linux version.
data "aws_ami" "flatcar_ami" {
  count = var.flatcar_linux_version != null ? 1 : 0

  owners = [var.flatcar_ami_owner]

  filter {
    name   = "name"
    values = ["Flatcar-${var.flatcar_linux_channel}-${module.flatcar_linux.flatcar_version}-*"]
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
    values = [var.flatcar_ami_owner]
  }
}

module "dns" {
  source = "../../../modules/aws/dns"

  cluster_name     = var.cluster_name
  root_dns_zone_id = var.root_dns_zone_id
  zone_name        = var.base_domain
}

module "vpc" {
  source = "../../../modules/aws/vpc"

  additional_tags    = var.additional_tags
  arn_region         = var.arn_region
  aws_account        = var.aws_account
  aws_cni_cidr_v2    = var.aws_cni_cidr_v2
  aws_cni_subnets_v2 = var.aws_cni_subnets_v2
  cluster_name       = var.cluster_name
  subnets_bastion    = var.subnets_bastion
  subnets_elb        = var.subnets_elb
  subnets_worker     = var.subnets_worker
  subnets_vault      = var.subnets_vault
  transit_vpc_cidr   = var.transit_vpc_cidr
  vpc_cidr           = var.vpc_cidr
  vpc_vgw_id         = var.vpc_vgw_id
  with_public_access = (var.aws_customer_gateway_id_0 != "") || (var.transit_vpc_cidr != "") ? false : true
}

# Create S3 bucket for ignition configs.
module "s3" {
  source = "../../../modules/aws/s3"

  additional_tags      = var.additional_tags
  aws_account          = var.aws_account
  cluster_name         = var.cluster_name
  logs_expiration_days = var.logs_expiration_days
  s3_bucket_prefix     = var.s3_bucket_prefix
}

# Create SQS queue for auto draining of nodes on instance termination.
module "sqs" {
  source = "../../../modules/aws/sqs"

  aws_account     = var.aws_account
  aws_region      = var.aws_region
  cluster_name    = var.cluster_name
  additional_tags = var.additional_tags
}

locals {
  ignition_data = {
    "AdditionalTags"               = local.additional_tags_ignition
    "AvaiabilityZones"             = data.aws_availability_zones.available.names
    "APIDomainName"                = "${var.api_dns}.${var.base_domain}"
    "APIInternalDomainName"        = "${var.api_internal_dns}.${var.base_domain}"
    "AWSRegion"                    = var.aws_region
    "BastionSubnet0"               = element(var.subnets_bastion, 0)
    "BastionSubnet1"               = element(var.subnets_bastion, 1)
    "BastionLogPriority"           = var.bastion_log_priority
    "BaseDomain"                   = var.base_domain
    "CNISubnets"                   = module.vpc.aws_cni_subnet_ids
    "CNISecurityGroupID"           = module.vpc.aws_cni_security_group_id
    "CloudwatchForwarderEnabled"   = var.bastion_log_priority != "none" ? "true" : "false"
    "ClusterDomain"                = var.cluster_domain
    "ClusterName"                  = var.cluster_name
    "DisableAPIFairness"           = var.disable_api_fairness
    "DockerCIDR"                   = var.docker_cidr
    "DockerRegistry"               = var.docker_registry
    "DockerRegistryMirror"         = var.docker_registry_mirror
    "ETCDEndpoints"                = "https://etcd1.${var.base_domain}:2379,https://etcd2.${var.base_domain}:2379,https://etcd3.${var.base_domain}:2379"
    "ETCDInitialClusterMulti"      = "etcd1=https://etcd1.${var.base_domain}:2380,etcd2=https://etcd2.${var.base_domain}:2380,etcd3=https://etcd3.${var.base_domain}:2380"
    "ETCDInitialClusterSingle"     = "etcd1=https://etcd1.${var.base_domain}:2380"
    "ExternalVpnGridscaleIp"       = var.external_ipsec_public_ip_0
    "ExternalVpnGridscalePassword" = var.external_ipsec_password
    "ExternalVpnGridscaleSubnet"   = var.external_ipsec_subnet_0
    "ExternalVpnGridscaleSourceIp" = cidrhost(var.external_ipsec_subnet_0, 1)
    "ExternalVpnVultrIp"           = var.external_ipsec_public_ip_1
    "ExternalVpnVultrPassword"     = var.external_ipsec_password
    "ExternalVpnVultrSubnet"       = var.external_ipsec_subnet_1
    "ExternalVpnVultrSourceIp"     = cidrhost(var.external_ipsec_subnet_1, 1)
    "GSReleaseVersion"             = var.release_version
    "G8SVaultToken"                = var.nodes_vault_token
    "K8SAPIIP"                     = var.k8s_api_ip
    "K8SAuditWebhookPort"          = var.k8s_audit_webhook_port
    "K8SDNSIP"                     = var.k8s_dns_ip
    "K8SServiceCIDR"               = var.k8s_service_cidr
    "K8sVersion"                   = var.hyperkube_version
    "LogentriesEnabled"            = var.logentries_enabled
    "LogentriesPrefix"             = var.logentries_prefix
    "LogentriesToken"              = var.logentries_token
    "MasterCount"                  = var.master_count
    "MasterENISubnetSize"          = local.masters_eni_subnet_size
    "MasterMountDocker"            = var.master_instance["volume_docker"]
    "MasterMountETCD"              = var.master_instance["volume_etcd"]
    "OIDCIssuerURL"                = "https://${var.oidc_issuer_dns}.${var.base_domain}"
    "PodCIDR"                      = var.aws_cni_cidr_v2
    "NodePodCIDRSize"              = var.node_pod_cidr_size
    "PodInfraImage"                = var.pod_infra_image
    "Provider"                     = "aws"
    "Users"                        = yamldecode(base64decode(jsondecode(data.http.bastion_users.body).content))
    "VaultDomainName"              = "${var.vault_dns}.${var.base_domain}"
    "WorkerMountDocker"            = var.worker_instance["volume_docker"]
  }
}

# Generate ignition config.
data "gotemplate" "bastion" {
  template    = "${path.module}/../../../templates/bastion.yaml.tmpl"
  data        = jsonencode(merge(local.ignition_data, { "NodeType" = "bastion" }))
  is_ignition = true
}

module "bastion" {
  source = "../../../modules/aws/bastion"

  additional_tags        = var.additional_tags
  arn_region             = var.arn_region
  aws_account            = var.aws_account
  aws_cni_subnets        = var.aws_cni_subnets_v2
  bastion_count          = "2"
  bastion_subnet_ids     = module.vpc.bastion_subnet_ids
  cluster_name           = var.cluster_name
  container_linux_ami_id = data.aws_ami.flatcar_ami[0].image_id
  dns_zone_id            = module.dns.public_dns_zone_id
  forward_logs_enabled   = var.bastion_forward_logs_enabled
  ignition_bucket_id     = module.s3.ignition_bucket_id
  iam_region             = var.iam_region
  instance_type          = var.bastion_instance_type
  s3_bucket_tags         = var.s3_bucket_tags
  transit_vpc_cidr       = var.transit_vpc_cidr
  user_data              = data.gotemplate.bastion.rendered
  with_public_access     = (var.aws_customer_gateway_id_0 != "") || (var.transit_vpc_cidr != "") ? false : true
  vpc_cidr               = var.vpc_cidr
  vpc_id                 = module.vpc.vpc_id
}

# Generate ignition config.
data "gotemplate" "vault" {
  template    = "${path.module}/../../../templates/vault.yaml.tmpl"
  data        = jsonencode(merge(local.ignition_data, { "NodeType" = "vault" }))
  is_ignition = true
}

module "vault" {
  source = "../../../modules/aws/vault"

  additional_tags        = var.additional_tags
  arn_region             = var.arn_region
  aws_account            = var.aws_account
  aws_cni_cidr_block     = var.aws_cni_cidr_v2
  aws_region             = var.aws_region
  cluster_name           = var.cluster_name
  container_linux_ami_id = data.aws_ami.flatcar_ami[0].image_id
  dns_zone_id            = module.dns.public_dns_zone_id
  elb_subnet_ids         = module.vpc.elb_subnet_ids
  ignition_bucket_id     = module.s3.ignition_bucket_id
  iam_region             = var.iam_region
  instance_type          = var.vault_instance_type
  user_data              = data.gotemplate.vault.rendered
  s3_bucket_tags         = var.s3_bucket_tags
  vault_count            = "1"
  vault_dns              = var.vault_dns
  vault_subnet_ids       = module.vpc.vault_subnet_ids
  vpc_cidr               = var.vpc_cidr
  ipam_network_cidr      = var.ipam_network_cidr
  vpc_id                 = module.vpc.vpc_id
  worker_subnet_ids      = module.vpc.worker_subnet_ids
  worker_subnet_count    = length(module.vpc.worker_subnet_ids)
}

# Ingress ELB
module "ingress" {
  source = "../../../modules/aws/ingress"

  additional_tags = var.additional_tags
  cluster_name    = var.cluster_name
  dns_zone_id     = module.dns.public_dns_zone_id
  elb_subnet_ids  = module.vpc.elb_subnet_ids
  ingress_dns     = var.ingress_dns
  vpc_id          = module.vpc.vpc_id
}

# Generate ignition config.
data "gotemplate" "master" {
  count = var.master_count

  template    = "${path.module}/../../../templates/master.yaml.tmpl"
  data        = jsonencode(merge(local.ignition_data, { "NodeType" = "master", "MasterID" = count.index + 1, "ETCDDomainName" = "etcd${count.index + 1}.${var.base_domain}", "MasterENIAddress" = local.masters_eni_ips[count.index], "MasterENIGateway" = local.masters_eni_gateways[count.index] }))
  is_ignition = true
}

module "master" {
  source = "../../../modules/aws/master"

  depends_on = [
    module.sqs
  ]

  master_count = var.master_count

  additional_tags              = var.additional_tags
  api_dns                      = var.api_dns
  api_internal_dns             = var.api_internal_dns
  aws_account                  = var.aws_account
  aws_region                   = var.aws_region
  aws_cni_cidr_block           = var.aws_cni_cidr_v2
  cluster_name                 = var.cluster_name
  container_linux_ami_id       = data.aws_ami.flatcar_ami[0].image_id
  customer_vpn_public_subnets  = var.customer_vpn_public_subnets
  customer_vpn_private_subnets = var.customer_vpn_private_subnets
  dns_zone_id                  = module.dns.public_dns_zone_id
  elb_subnet_ids               = module.vpc.elb_subnet_ids
  external_ipsec_public_ip_0   = var.external_ipsec_public_ip_0
  external_ipsec_public_ip_1   = var.external_ipsec_public_ip_1
  ignition_bucket_id           = module.s3.ignition_bucket_id
  instance_type                = var.master_instance["type"]
  user_data                    = data.gotemplate.master.*.rendered
  master_subnet_ids            = module.vpc.worker_subnet_ids
  master_eni_ips               = local.masters_eni_ips
  nat_gateway_public_ips       = module.vpc.aws_eip_public_ips
  sqs_temination_queue_arn     = module.sqs.termination_queue_arn
  volume_docker                = var.master_instance["volume_docker"]
  volume_etcd                  = var.master_instance["volume_etcd"]
  vpc_cidr                     = var.vpc_cidr
  vpc_id                       = module.vpc.vpc_id
  iam_region                   = var.iam_region
  s3_bucket_tags               = var.s3_bucket_tags
  arn_region                   = var.arn_region
}

# Generate ignition config.
data "gotemplate" "worker" {
  template    = "${path.module}/../../../templates/worker.yaml.tmpl"
  data        = jsonencode(merge(local.ignition_data, { "NodeType" = "worker" }))
  is_ignition = true
}

module "worker" {
  source = "../../../modules/aws/worker-asg"

  depends_on = [
    module.sqs
  ]

  additional_tags          = var.additional_tags
  aws_account              = var.aws_account
  aws_region               = var.aws_region
  aws_cni_cidr_block       = var.aws_cni_cidr_v2
  cluster_name             = var.cluster_name
  container_linux_ami_id   = data.aws_ami.flatcar_ami[0].image_id
  dns_zone_id              = module.dns.public_dns_zone_id
  elb_subnet_ids           = module.vpc.elb_subnet_ids
  ignition_bucket_id       = module.s3.ignition_bucket_id
  ingress_dns              = var.ingress_dns
  instance_type            = var.worker_instance["type"]
  user_data                = data.gotemplate.worker.rendered
  worker_count             = var.worker_count
  worker_subnet_ids        = module.vpc.worker_subnet_ids
  sqs_temination_queue_arn = module.sqs.termination_queue_arn
  volume_docker            = var.worker_instance["volume_docker"]
  vpc_cidr                 = var.vpc_cidr
  vpc_id                   = module.vpc.vpc_id
  iam_region               = var.iam_region
  s3_bucket_tags           = var.s3_bucket_tags
  arn_region               = var.arn_region
}

module "vpn" {
  source = "../../../modules/aws/vpn"

  additional_tags             = var.additional_tags
  # If aws_customer_gateway_id_0 is not set, no vpn resources will be created.
  aws_customer_gateway_id_0   = var.aws_customer_gateway_id_0
  aws_customer_gateway_id_1   = var.aws_customer_gateway_id_1
  aws_cluster_name            = var.cluster_name
  aws_external_ipsec_subnet_0 = var.external_ipsec_subnet_0
  aws_external_ipsec_subnet_1 = var.external_ipsec_subnet_1
  aws_private_route_table_ids = module.vpc.private_route_table_ids
  aws_vpn_name                = "Giant Swarm <-> ${var.cluster_name}"
  aws_vpn_vpc_id              = module.vpc.vpc_id
}

terraform {
  required_version = ">= 0.12.6"

  backend "s3" {}
}
