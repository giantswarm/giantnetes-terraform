variable "arn_region" {
  type    = "string"
  default = "aws"
}

variable "cluster_name" {
  type        = "string"
  description = "Need to be unique within the account"
}

variable "aws_region" {
  type        = "string"
  description = "An AWS region where the cluster will be built."
}

variable "aws_account" {
  type        = "string"
  description = "An AWS account ID."
}

variable "ami_owner" {
  type        = "string"
  default     = "595879546273"
  description = "ID of the ami owner for CoreOS images."
}

variable "bastion_log_priority" {
  type        = "string"
  default     = "none"
  description = "Default log priority for exported logs (based on journalctl priorities)"
}

variable "bastion_forward_logs_enabled" {
  default     = true
  description = "Enable forwarding bastions logs to cloudwatch."
}

variable "iam_region" {
  type    = "string"
  default = "ec2.amazonaws.com"
}

variable "nodes_vault_token" {
  type        = "string"
  description = "Vault token used by nodes for bootstrapping. Should be defined after Vault is installed."
}

variable "master_count" {
  type        = "string"
  description = "Number of master nodes to be created. Supported values 1 (single master) or 3 (multi master)."
  default     = "3"
}

variable "worker_count" {
  type        = "string"
  description = "Number of worker nodes to be created."
  default     = "3"
}

variable "logs_expiration_days" {
  type        = "string"
  description = "Number of days access logs will be stored in logging bucket."
  default     = "365"
}

variable "s3_bucket_tags" {
  default = true
}

### Compute and Storage ###

variable "bastion_instance_type" {
  type    = "string"
  default = "t2.micro"
}

variable "vault_instance_type" {
  type    = "string"
  default = "t2.medium"
}

variable "vault_auto_unseal" {
  default = true
}

variable "master_instance" {
  type = "map"

  default = {
    type          = "m5.large"
    volume_docker = "/dev/xvdc"
    volume_etcd   = "/dev/xvdh"
  }
}

variable "worker_instance" {
  type = "map"

  default = {
    type          = "m5.xlarge"
    volume_docker = "/dev/xvdc"
  }
}

### Container Linux ###
variable "container_linux_channel" {
  description = "Container linux channel (e.g. stable, beta, alpha)."
  default     = "stable"
}

variable "container_linux_version" {
  description = "Container linux version."
  default     = "latest"
}

variable "docker_registry" {
  type    = "string"
  default = "quay.io"
}

### DNS ###

variable "base_domain" {
  type        = "string"
  description = "Base domain for g8s cluster (e.g $CLUSTER_NAME.$AWS_REGION.aws.gigantic.io)."
}

variable "vault_dns" {
  type        = "string"
  description = "vault DNS prefix (i.e. vault)."
  default     = "vault"
}

variable "api_dns" {
  type        = "string"
  description = "FQDN for api (i.e. g8s)."
  default     = "g8s"
}

variable "etcd_dns" {
  type        = "string"
  description = "FQDN for etcd (i.e. etcd). '__MASTER_ID__' wil be replaced with id of master"
  default     = "etcd__MASTER_ID__"
}

variable "ingress_dns" {
  type        = "string"
  description = "FQDN for ingress (i.e. ingress)."
  default     = "ingress"
}

variable "root_dns_zone_id" {
  description = "Root DNS zone id"
  default     = ""
}

variable "route53_enabled" {
  default = true
}

### Machine ID ###
variable "master_id" {
  description = "Define master id in multi-master cluster."
  default     = "__MASTER_ID__"
}

### Network ###

variable "vpc_cidr" {
  description = "CIDR for VMs internal virtual network."
  default     = "10.0.0.0/16"
}

variable "calico_cidr" {
  description = "CIDR for Calico."
  default     = "192.168.0.0/16"
}

variable "calico_mtu" {
  description = "MTU used for Calico interfaces"
  default     = "1440"
}

variable "docker_cidr" {
  description = "CIDR for Docker."
  default     = "172.17.0.1/16"
}

variable "ipam_network_cidr" {
  description = "CIDR for guest VMs internal virtual network."
  type        = "string"
  default     = "10.1.0.0/16"
}

variable "k8s_service_cidr" {
  description = "CIDR for k8s internal cluster network."
  default     = "172.31.0.0/16"
}

variable "k8s_dns_ip" {
  description = "IP for k8s internal DNS server."
  default     = "172.31.0.10"
}

variable "k8s_api_ip" {
  description = "IP for k8s internal API server."
  default     = "172.31.0.1"
}

variable "subnets_bastion" {
  description = "CIDR for bastion networks"
  type        = "list"
  default     = ["10.0.1.0/25", "10.0.1.128/25"]
}

variable "subnets_elb" {
  description = "CIDR for load balancer networks."
  type        = "list"
  default     = ["10.0.2.0/26", "10.0.2.64/26", "10.0.2.128/26"]
}

variable "subnets_vault" {
  description = "CIDR for Vault network."
  default     = ["10.0.3.0/25"]
}

variable "subnets_worker" {
  description = "CIDR for worker networks"
  type        = "list"
  default     = ["10.0.5.0/26", "10.0.5.64/26", "10.0.5.128/26"]
}

### VPN ###

variable "aws_customer_gateway_id_0" {
  description = "AWS customer gateway ID. Should be created manually. Leave blank to disable VPN setup and enable public access for bastions."
  default     = ""
}

variable "aws_customer_gateway_id_1" {
  description = "AWS customer gateway ID. Should be created manually."
  default     = ""
}

variable "external_ipsec_subnet_0" {
  description = "CIDR of peering IPSec network."
  default     = "172.18.0.0/30"
}

variable "external_ipsec_subnet_1" {
  description = "CIDR of peering IPSec network."
  default     = "172.18.0.4/30"
}

### VPN with custom instance 
variable "vpn_instance_enabled" {
  default = false
  type = bool
}

## Gridscale
variable "external_ipsec_public_ip_0" {
  description = "External public ip from VPN 0 - Gridscale"
  type        = "string"
  default     = "185.102.95.187"
}

## Vultr
variable "external_ipsec_public_ip_1" {
  description = "External public cidr from VPN 1 - Vultr"
  type        = "string"
  default     = "95.179.153.65"
}

## vpn password
variable "external_ipsec_password" {
  description = "shared password for ipsec connection"
  type        = "string"
  default     = "_none_"
}

### Kubernetes ###
variable "image_pull_progress_deadline" {
  default = "1m"
}

variable "pod_infra_image" {
  default = "giantswarm/pause-amd64:3.1"
}
