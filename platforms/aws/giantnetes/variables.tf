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

variable "nodes_vault_token" {
  type        = "string"
  description = "Vault token used by nodes for bootstrapping. Should be defined after Vault is installed."
}

variable "worker_count" {
  type        = "string"
  description = "Number of worker nodes to be created."
  default     = "4"
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

variable "master_instance_type" {
  type    = "string"
  default = "m4.large"
}

variable "worker_instance_type" {
  type    = "string"
  default = "m4.xlarge"
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

variable "outside_encryption_domain" {
  description = "CIDR of peering IPSec network."
  default     = "172.18.0.0/30"
}

variable "aws_customer_gateway_id" {
  description = "CIDR of peering IPSec network."
  default     = ""
}
