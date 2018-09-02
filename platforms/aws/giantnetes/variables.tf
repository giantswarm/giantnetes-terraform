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

variable "iam_region" {
  type    = "string"
  default = "ec2.amazonaws.com"
}

variable "nodes_vault_token" {
  type        = "string"
  description = "Vault token used by nodes for bootstrapping. Should be defined after Vault is installed."
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

variable "master_instance" {
  type = "map"

  default = {
    type         = "m5.large"
    mount_docker = "/dev/nvme1n1"
    mount_etcd   = "/dev/nvme2n1"
    volume_etcd  = "/dev/xvdh"
  }
}

variable "worker_instance" {
  type = "map"

  default = {
    type          = "m5.xlarge"
    mount_docker  = "/dev/nvme1n1"
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
  description = "FQDN for etcd (i.e. etcd)."
  default     = "etcd"
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

### Network ###

variable "vpc_cidr" {
  description = "CIDR for VMs internal virtual network."
  default     = "10.0.0.0/16"
}

variable "calico_cidr" {
  description = "CIDR for Calico."
  default     = "192.168.0.0/16"
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

variable "subnet_bastion_0" {
  description = "CIDR for bastion network 0."
  default     = "10.0.1.0/25"
}

variable "subnet_bastion_1" {
  description = "CIDR for bastion network 1."
  default     = "10.0.1.128/25"
}

variable "subnet_elb_0" {
  description = "CIDR for load balancer network 0."
  default     = "10.0.2.0/25"
}

variable "subnet_elb_1" {
  description = "CIDR for load balancer network 1."
  default     = "10.0.2.128/25"
}

variable "subnet_vault_0" {
  description = "CIDR for Vault network."
  default     = "10.0.3.0/25"
}

variable "subnet_worker_0" {
  description = "CIDR for worker network 0."
  default     = "10.0.5.0/25"
}

variable "subnet_worker_1" {
  description = "CIDR for worker network 1."
  default     = "10.0.5.128/25"
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

### Kubernetes ###
variable "image_pull_progress_deadline" {
  default = "1m"
}

variable "pod_infra_image" {
  default = "gcr.io/google_containers/pause-amd64:3.1"
}
