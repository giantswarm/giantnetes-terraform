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
  content      = "${data.template_file.bastion.rendered}"
  platform     = "ec2"
  pretty_print = false
}

module "bastion" {
  source = "../../../modules/aws/bastion"

  bastion_count          = "2"
  bastion_subnet_ids     = "${module.vpc.bastion_subnet_ids}"
  cluster_name           = "${var.cluster_name}"
  container_linux_ami_id = "${data.aws_ami.coreos_ami.image_id}"
  dns_zone_id            = "${module.dns.public_dns_zone_id}"
  instance_type          = "${var.bastion_instance_type}"
  user_data              = "${data.ct_config.bastion.rendered}"
  with_public_access     = "${var.aws_customer_gateway_id == "" ? 1 : 0 }"
  vpc_cidr               = "${var.vpc_cidr}"
  vpc_id                 = "${module.vpc.vpc_id}"
}

# Generate ignition config for Vault.
data "template_file" "vault" {
  template = "${file("${path.module}/../../../ignition/aws/vault.yaml.tmpl")}"

  vars {
    "DOCKER_CIDR" = "${var.docker_cidr}"
  }
}

# Convert ignition config to raw json and merge users part.
data "ct_config" "vault" {
  content      = "${format("%s\n%s", local.ignition_users, data.template_file.vault.rendered)}"
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
  vault_count            = "1"
  vault_dns              = "${var.vault_dns}"
  vault_subnet_ids       = "${module.vpc.vault_subnet_ids}"
  vpc_cidr               = "${var.vpc_cidr}"
  vpc_id                 = "${module.vpc.vpc_id}"
}

# Generate ignition config for master.
data "template_file" "master" {
  template = "${file("${path.module}/../../../ignition/aws/master.yaml.tmpl")}"

  vars {
    "API_DOMAIN_NAME"   = "${var.api_dns}.${var.base_domain}"
    "CALICO_CIDR"       = "${var.calico_cidr}"
    "DEFAULT_IPV4"      = "$${DEFAULT_IPV4}"
    "DOCKER_CIDR"       = "${var.docker_cidr}"
    "ETCD_DOMAIN_NAME"  = "${var.etcd_dns}.${var.base_domain}"
    "G8S_VAULT_TOKEN"   = "${var.nodes_vault_token}"
    "K8S_SERVICE_CIDR"  = "${var.k8s_service_cidr}"
    "K8S_DNS_IP"        = "${var.k8s_dns_ip}"
    "K8S_API_IP"        = "${var.k8s_api_ip}"
    "VAULT_DOMAIN_NAME" = "${var.vault_dns}.${var.base_domain}"
  }
}

# Convert ignition config to raw json and merge users part.
data "ct_config" "master" {
  content      = "${format("%s\n%s", local.ignition_users, data.template_file.master.rendered)}"
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
  ignition_bucket_id     = "${module.s3.ignition_bucket_id}"
  instance_type          = "${var.master_instance_type}"
  user_data              = "${data.ct_config.master.rendered}"
  master_subnet_ids      = "${module.vpc.worker_subnet_ids}"
  vpc_cidr               = "${var.vpc_cidr}"
  vpc_id                 = "${module.vpc.vpc_id}"
}

# Generate ignition config for worker.
data "template_file" "worker" {
  template = "${file("${path.module}/../../../ignition/aws/worker.yaml.tmpl")}"

  vars {
    "API_DOMAIN_NAME"   = "${var.api_dns}.${var.base_domain}"
    "CALICO_CIDR"       = "${var.calico_cidr}"
    "DEFAULT_IPV4"      = "$${DEFAULT_IPV4}"
    "DOCKER_CIDR"       = "${var.docker_cidr}"
    "ETCD_DOMAIN_NAME"  = "${var.etcd_dns}.${var.base_domain}"
    "G8S_VAULT_TOKEN"   = "${var.nodes_vault_token}"
    "K8S_DNS_IP"        = "${var.k8s_dns_ip}"
    "VAULT_DOMAIN_NAME" = "${var.vault_dns}.${var.base_domain}"
  }
}

# Convert ignition config to raw json and merge users part.
data "ct_config" "worker" {
  content      = "${format("%s\n%s", local.ignition_users, data.template_file.worker.rendered)}"
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
  instance_type          = "${var.worker_instance_type}"
  user_data              = "${data.ct_config.worker.rendered}"
  worker_count           = 4
  worker_subnet_ids      = "${module.vpc.worker_subnet_ids}"
  vpc_cidr               = "${var.vpc_cidr}"
  vpc_id                 = "${module.vpc.vpc_id}"
}

module "vpn" {
  source = "../../../modules/aws/vpn"

  # If aws_customer_gateway_id is not set, no vpn resources will be created.
  aws_customer_gateway_id    = "${var.aws_customer_gateway_id}"
  aws_external_ipsec_subnet  = "${var.external_ipsec_subnet}"
  aws_public_route_table_ids = "${module.vpc.public_route_table_ids}"
  aws_vpn_name               = "Giant Swarm <-> ${var.cluster_name}"
  aws_vpn_vpc_id             = "${module.vpc.vpc_id}"
}
