#!/bin/bash

# opsctl path
OPSCTL_PATH=${OPSCTL_PATH:-opsctl}

# This file overrides terraform.tfvars values.

# azure location without spaces (e.g. westeurope)
export TF_VAR_azure_location=westeurope
# needs to be unique within the azure account
export TF_VAR_cluster_name=godsmack

# will be added within the installation process
export TF_VAR_nodes_vault_token="$(${OPSCTL_PATH} show secret -i ./terraform-secrets.yaml -k Terraform.VaultToken)"

# service principal credentials
export TF_VAR_azure_sp_tenantid=31f75bf9-3d8c-4691-95c0-83dd71613db8
export TF_VAR_azure_sp_subscriptionid=1be3b2e6-497b-45b9-915f-eb35cae23c6a
export TF_VAR_azure_sp_aadclientid=6463ec6f-0267-4d93-80c8-5b7d4d37f845


export TF_VAR_azure_sp_aadclientsecret="$(${OPSCTL_PATH} show secret -i ./terraform-secrets.yaml -k Terraform.AzureSPAadClientSecret)"
export ARM_ACCESS_KEY="$(${OPSCTL_PATH} show secret -i ./terraform-secrets.yaml -k Terraform.ArmAccessKey)"

# example is a standard gigantic.io domain structure.
# pls don't change if this cluster is installed with gigantic.io
#
# if you'd like to configure a custom domain please only change
# TF_VAR_base_domain (replace "azure.gigantic.io" with the custom
# domain)
export TF_VAR_base_domain=${TF_VAR_cluster_name}.${TF_VAR_azure_location}.azure.gigantic.io
# hosted zone name, leave empty to setup DNS manually
export TF_VAR_root_dns_zone_name="azure.gigantic.io"

# Override here any option from platforms/azure/variables.tf
export TF_VAR_vpn_enabled=1
export TF_VAR_vpn_right_gateway_address_0=185.102.95.187
export TF_VAR_vpn_right_gateway_address_1=95.179.153.65
export TF_VAR_bastion_cidr=10.0.4.0/28
export TF_VAR_container_linux_version=1995.0.0
# TODO: Remove this as soon as AWS/Azure latest stable 1995.0.0 images will be available.
# https://coreos.com/os/docs/latest/booting-on-ec2.html
# https://coreos.com/os/docs/latest/booting-on-azure.html
export TF_VAR_container_linux_channel=alpha
export TF_VAR_vault_vm_objectid=
export TF_VAR_terraform_group_id=28a3d75d-946c-45dc-b3b0-707a85213141

terraform init -backend=true \
-backend-config="storage_account_name=${TF_VAR_cluster_name}terraform" \
-backend-config="key=terraform" \
-backend-config="container_name=${TF_VAR_cluster_name}-state" \
 ./
