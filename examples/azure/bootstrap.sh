#!/bin/bash

# Remove synced states
rm .terraform -Rf

# Unset all the previously exported vars
exported_vars=$(env | grep TF_VAR | cut -d "=" -f1)
if [ "${exported_vars}" = $'\n' ]; then
  while read -r exported_var; do
    unset ${exported_var}
  done <<< ${exported_vars}
fi

# Checkout desired version
RELEASE_VERSION=${RELEASE_VERSION:-v<Use latest version of giantnetes-terraform>}
export TF_VAR_release_version=${RELEASE_VERSION}
git fetch --all --tags
git checkout ${RELEASE_VERSION} || return

# opsctl path
OPSCTL_PATH=${OPSCTL_PATH:-opsctl}

# This file overrides terraform.tfvars values.

# azure location without spaces (e.g. westeurope)
export TF_VAR_azure_location=<value>
# needs to be unique within the azure account
export TF_VAR_cluster_name=<value>

# Leave empty at the beginning. After you'll have vault deployed, you will need to copy the "VAULT TOKEN for the g8s host cluster" in here.
export TF_VAR_nodes_vault_token="$(${OPSCTL_PATH} show secret -i ./terraform-secrets.yaml -k Terraform.VaultToken)"

# service principal credentials
export TF_VAR_azure_sp_tenantid=<value>
# account subscription id (from az account list --output table)
export TF_VAR_azure_sp_subscriptionid=<value>
# equals to azure appId
export TF_VAR_azure_sp_aadclientid=<value>


export TF_VAR_azure_sp_aadclientsecret="$(${OPSCTL_PATH} show secret -i ./terraform-secrets.yaml -k Terraform.AzureSPAadClientSecret)"
export ARM_ACCESS_KEY="$(${OPSCTL_PATH} show secret -i ./terraform-secrets.yaml -k Terraform.ArmAccessKey)"

export TF_VAR_base_domain=${TF_VAR_cluster_name}.${TF_VAR_azure_location}.azure.gigantic.io
# hosted zone name. This is the zone where the delegated NS records are set.
# If the installation is in the same subscription, populate the following variable.
# Otherwise leave empty and create the delegation records manually.
export TF_VAR_root_dns_zone_name=""

# To enable Site-To-Site IPSec uncomment following options. Make sure that bastion subnet is unique across installations.
# export TF_VAR_vpn_enabled=1
# export TF_VAR_vpn_right_gateway_address_0=185.102.95.187
# export TF_VAR_vpn_right_gateway_address_1=95.179.153.65
# export TF_VAR_bastion_cidr=<bastion subnet i.e. 10.0.4.112/28>

# Override here any option from platforms/azure/variables.tf
# master nodes size
# export TF_VAR_master_vm_size="Standard_D8s_v3"
# worker nodes size
# export TF_VAR_worker_vm_size="Standard_D8s_v3"
# OIDC setup
#export TF_VAR_customer_vpn_public_subnets="0.0.0.0/0"
#export TF_VAR_oidc_enabled=true

terraform init -backend=true \
-backend-config="storage_account_name=${TF_VAR_cluster_name}terraform" \
-backend-config="key=terraform" \
-backend-config="container_name=${TF_VAR_cluster_name}-state" \
 ./
