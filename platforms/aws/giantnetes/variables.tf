variable "github_token" {
  type        = string
  description = "Your personal GITHUB token, used to get access to the private repository 'employees' to get the list of users."
}

variable "employees_branch" {
  type        = string
  description = "The branch in the 'employees' repo to use for getting a list of users"
  default     = "master"
}

variable "arn_region" {
  type    = string
  default = "aws"
}

variable "cluster_name" {
  type        = string
  description = "Need to be unique within the account"
}

variable "aws_region" {
  type        = string
  description = "An AWS region where the cluster will be built."
}

variable "aws_account" {
  type        = string
  description = "An AWS account ID."
}

variable "bastion_log_priority" {
  type        = string
  default     = "none"
  description = "Default log priority for exported logs (based on journalctl priorities)"
}

variable "bastion_forward_logs_enabled" {
  default     = true
  description = "Enable forwarding bastions logs to cloudwatch."
}

variable "iam_region" {
  type    = string
  default = "ec2.amazonaws.com"
}

variable "nodes_vault_token" {
  type        = string
  description = "Vault token used by nodes for bootstrapping. Should be defined after Vault is installed."
  default     = ""
}

variable "master_count" {
  type        = string
  description = "Number of master nodes to be created. Supported values 1 (single master) or 3 (multi master)."
  default     = "3"
}

variable "worker_count" {
  type        = string
  description = "Number of worker nodes to be created."
  default     = "4"
}

variable "logs_expiration_days" {
  type        = string
  description = "Number of days access logs will be stored in logging bucket."
  default     = "365"
}

variable "s3_bucket_prefix" {
  default = ""
}

variable "s3_bucket_tags" {
  default = true
}

### Compute and Storage ###

variable "bastion_instance_type" {
  type    = string
  default = "t3.small"
}

variable "vault_instance_type" {
  type    = string
  default = "t2.medium"
}

variable "master_instance" {
  type = map(any)

  default = {
    type          = "m5.xlarge"
    volume_docker = "/dev/xvdc"
    volume_etcd   = "/dev/xvdh"
  }
}

variable "worker_instance" {
  type = map(any)

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

### Flatcar Linux ###
variable "flatcar_linux_channel" {
  description = "Flatcar linux channel (e.g. stable, beta, alpha)."
  default     = "stable"
}


## If explicity set it up, Flatcar will be used installed instead of CoreOS
variable "flatcar_linux_version" {
  description = "Flatcar linux version."
  type        = string
  default     = "3510.2.1"
}

variable "flatcar_ami_owner" {
  description = "Flatcar linux AWS ID account."
  default     = "075585003325"
}

variable "docker_registry" {
  type    = string
  default = "docker.io"
}

variable "docker_registry_mirror" {
  type    = string
  default = "giantswarm.azurecr.io"
}

variable "hyperkube_version" {
  type    = string
  default = "1.24.12"
}

### DNS ###

variable "base_domain" {
  type        = string
  description = "Base domain for g8s cluster (e.g $CLUSTER_NAME.$AWS_REGION.aws.gigantic.io)."
}

variable "vault_dns" {
  type        = string
  description = "vault DNS prefix (i.e. vault)."
  default     = "vault"
}

variable "api_dns" {
  type        = string
  description = "fqdn for api (i.e. g8s)."
  default     = "g8s"
}

variable "api_internal_dns" {
  type        = string
  description = "fqdn for internal api (i.e. internal-g8s)."
  default     = "internal-g8s"
}

variable "ingress_dns" {
  type        = string
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

variable "aws_cni_cidr_v2" {
  description = "Whole CIDR block for AWS CNI. Using CGNAT range for all CPs."
  default     = "100.64.0.0/16"
}

variable "aws_cni_subnets_v2" {
  type        = list(any)
  description = "CIDR for AWS CNI networks used for pods."
  default     = ["100.64.0.0/18", "100.64.64.0/18", "100.64.128.0/18"]
}

variable "node_pod_cidr_size" {
  description = "Size of Pod CIDR to be allocated for each node."
  type        = string
  default     = "25"
}

variable "docker_cidr" {
  description = "CIDR for Docker."
  default     = "172.17.0.1/16"
}

variable "ipam_network_cidr" {
  description = "CIDR for guest VMs internal virtual network."
  type        = string
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

variable "k8s_audit_webhook_port" {
  description = "Port for audit webhook streaming."
  default     = "30771"
}

variable "subnets_bastion" {
  description = "CIDR for bastion networks"
  type        = list(any)
  default     = ["10.0.1.0/25", "10.0.1.128/25"]
}

variable "subnets_elb" {
  description = "CIDR for load balancer networks."
  type        = list(any)
  default     = ["10.0.2.0/26", "10.0.2.64/26", "10.0.2.128/26"]
}

variable "subnets_vault" {
  description = "CIDR for Vault network."
  type        = list(any)
  default     = ["10.0.3.0/25"]
}

variable "subnets_worker" {
  description = "CIDR for worker networks"
  type        = list(any)
  default     = ["10.0.5.0/26", "10.0.5.64/26", "10.0.5.128/26"]
}

### Access via transit VPC ###
variable "vpc_vgw_id" {
  description = "ID of the virtual private gateway, attached to VPC."
  default     = ""
  type        = string
}

variable "transit_vpc_cidr" {
  description = "CIDR of the transit VPC, used to access installation bastions"
  default     = ""
  type        = string
}

### OIDC ###

variable "oidc_issuer_dns" {
  type        = string
  description = "subdomain for oidc issuer (i.e. dex.g8s)."
  default     = "dex.g8s"
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

## Gridscale
variable "external_ipsec_public_ip_0" {
  description = "External public ip from VPN 0 - Gridscale"
  type        = string
  default     = "185.102.95.187"
}

## Vultr
variable "external_ipsec_public_ip_1" {
  description = "External public cidr from VPN 1 - Vultr"
  type        = string
  default     = "95.179.153.65"
}

## vpn password
variable "external_ipsec_password" {
  description = "shared password for ipsec connection"
  type        = string
  default     = "_none_"
}

### Kubernetes ###
variable "pod_infra_image" {
  default = "giantswarm/pause-amd64:3.3"
}

### External Kubernetes API Access
variable "customer_vpn_public_subnets" {
  description = "Comma separated list of customer networks for k8s public API external access"
  type        = string
  default     = ""
}

variable "customer_vpn_private_subnets" {
  description = "Comma separated list of customer networks for k8s private API external access"
  type        = string
  default     = ""
}


### CI
variable "logentries_enabled" {
  default = false
  type    = bool
}

variable "logentries_prefix" {
  description = "Prefix string, appended to log lines"
  type        = string
  default     = "none"
}

variable "logentries_token" {
  description = "Token, used to authorize in logging service"
  type        = string
  default     = "none"
}

### Release information
variable "release_version" {
  description = "Giantnetes terraform release version"
  type        = string
  default     = ""
}

### additional tags
variable "additional_tags" {
  description = "Additional tags that can be added to all resources"
  type        = map(string)
  default     = {}
}

### cluster domain
variable "cluster_domain" {
  description = "clusterDomain setting for kubelet"
  type        = string
  default     = "cluster.local"
}

# If set to true, the kubernetes API fairness mechanism is disabled.
variable "disable_api_fairness" {
  default = false
  type    = bool
}
