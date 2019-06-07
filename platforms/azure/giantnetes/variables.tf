variable "cluster_name" {
  type        = "string"
  description = "Need to be unique within the account"
}

variable "azure_location" {
  type        = "string"
  description = "An Azure location where the cluster will be built."
}

variable "azure_cloud" {
  description = "Azure cloud to use. Possible values can be found here: https://github.com/Azure/go-autorest/blob/ec5f4903f77ed9927ac95b19ab8e44ada64c1356/autorest/azure/environments.go#L13"
  default     = "AZUREPUBLICCLOUD"
}

# Azure has different number of failure domains depending on location.
# For example, German cloud central location has 2 failure domains.
variable "platform_fault_domain_count" {
  type        = "string"
  description = "Number of failure domains to use for availability sets."
  default     = 3
}

variable "azure_sp_tenantid" {
  type        = "string"
  description = "Tenant ID of Service Principal for Kubernetes"
}

variable "azure_sp_subscriptionid" {
  type        = "string"
  description = "Subscription ID of Service Principal for Kubernetes"
}

variable "azure_sp_aadclientid" {
  type        = "string"
  description = "ID of Service Principal for Kubernetes"
}

variable "azure_sp_aadclientsecret" {
  type        = "string"
  description = "Secret of Service Principal for Kubernetes"
}

variable "nodes_vault_token" {
  type        = "string"
  description = "Vault token used by nodes for bootstrapping. Should be defined after Vault is installed."
}

variable "master_count" {
  type        = "string"
  description = "Number of master nodes to be created. Allowed values are 1 or 3."
  default     = "3"
}

variable "worker_count" {
  type        = "string"
  description = "Number of worker nodes to be created."
  default     = "3"
}

variable "terraform_group_id" {
  type        = "string"
  description = "Active Directory group ID with access to Key Vault"
  default     = ""
}

### Compute and Storage ###

variable "bastion_vm_size" {
  type    = "string"
  default = "Standard_A1"
}

variable "os_disk_storage_type" {
  type    = "string"
  default = "Standard_LRS"
}

variable "vault_vm_size" {
  type    = "string"
  default = "Standard_DS1_v2"
}

variable "vault_storage_type" {
  type    = "string"
  default = "Premium_LRS"
}

variable "vault_auto_unseal" {
  default = true
}

variable "master_vm_size" {
  type    = "string"
  default = "Standard_D2s_v3"
}

variable "master_storage_type" {
  type    = "string"
  default = "Premium_LRS"
}

variable "worker_vm_size" {
  type    = "string"
  default = "Standard_D4s_v3"
}

variable "worker_storage_type" {
  type    = "string"
  default = "Standard_LRS"
}

### Container Linux ###

variable "container_linux_channel" {
  description = "Cotainer linux channel (e.g. stable, beta, alpha)."
  default     = "stable"
}

variable "container_linux_version" {
  description = "Container linux version."
  default     = "latest"
}

variable "core_ssh_key" {
  description = "ssh key for user core"
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIvW4h8X48R38jYIkod5whXMhIL/9Zfgp+EwgkRZi4mn+OAbCprHwc4V3RUGW0ysEdEqI/4FI1ho57X8CbbLa03MazNCKHCd8CNGdGorKai0g4uRaJI4wp+J6wniqERdJjuRKvRVYEZt8Ptv7YS0i3uW2HUDPVipkEqmSUtF7t4lAD1FDtAGQN23bdDhWHfTUAfg5yooiHtm9JfKiEV7MwncMd1nlZIklJWMQf9W5dvJBPmhVU0XmaCsmOH2rvaCi+cZQiMCqJOBKzDnEupanGcaf76iCQ3dn1ToCxXLlnRvhgSL6thR9HC3vA/ivDReKO7BXB8FVuZnr7NT0oxGaz fake"
}

variable "docker_registry" {
  type    = "string"
  default = "quay.io"
}

### DNS ###

variable "base_domain" {
  type        = "string"
  description = "Base domain for g8s cluster (i.e. $cluster_name.$azure_location.azure.gigantic.io)."
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

variable "root_dns_zone_name" {
  description = "Root DNS zone name (i.e. azure.gigantic.io)"
  default     = ""
}

variable "root_dns_zone_rg" {
  description = "Root DNS zone resource group"
  default     = "root_dns_zone_rg"
}

### Machine ID ###
variable "master_id" {
  description = "Define master id in multi-master cluster."
  default     = "__MASTER_ID__"
}

### Network ###

variable "calico_mtu" {
  description = "MTU used for Calico interfaces"
  default     = "1500"
}

variable "vnet_cidr" {
  description = "CIDR for VMs internal virtual network."
  default     = "10.0.0.0/16"
}

# NOTE:
# - bastion_cidr should be a part of vnet_cidr.
# - bastion_cidr should be unique across all installations if VPN enabled.
# - recommended to use /28 subnets from range 10.0.4.0/22 (for default 10.0.0.0/16 vnet_cidr).
variable "bastion_cidr" {
  description = "CIDR for bastions."
  default     = "10.0.4.0/28"
}

variable "pod_cidr" {
  description = "CIDR for pods."
  default     = "10.0.128.0/17"
}

variable "docker_cidr" {
  description = "CIDR for Docker."
  default     = "172.17.0.1/16"
}

variable "k8s_service_cidr" {
  description = "CIDR for k8s internal cluster network."
  default     = "172.31.0.0/24"
}

variable "k8s_dns_ip" {
  description = "IP for k8s internal DNS server."
  default     = "172.31.0.10"
}

variable "k8s_api_ip" {
  description = "IP for k8s internal API server."
  default     = "172.31.0.1"
}

### VPN ###

# NOTE: VPN is disabled by default.
variable "vpn_enabled" {
  description = "Enable or disable VPN (1 - yes, 0 - no)."
  default     = "0"
}

variable "vpn_right_gateway_address_0" {
  description = "IP address of the remote IPSec endpoint."
  default     = ""
}

variable "vpn_right_gateway_address_1" {
  description = "IP address of the remote IPSec endpoint."
  default     = ""
}

variable "vpn_right_subnet_cidr_0" {
  description = "CIDR of the remote IPSec network."
  default     = "172.18.0.1/32"
}

variable "vpn_right_subnet_cidr_1" {
  description = "CIDR of the remote IPSec network."
  default     = "172.18.0.5/32"
}
