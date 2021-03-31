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
RELEASE_VERSION=${RELEASE_VERSION:-v3.3.1}
export TF_VAR_release_version=${RELEASE_VERSION}
git fetch --all --tags
git checkout ${RELEASE_VERSION} || return

# opsctl path
OPSCTL_PATH=${OPSCTL_PATH:-opsctl}

## VMWare TF state and DNS are hosted in our main GS AWS
## account. Therefore you normally shouldn't need to
## change the following settings

# AWS account ID
export TF_VAR_aws_account=084190472784

export AWS_PROFILE=giantswarm
export AWS_DEFAULT_REGION=eu-central-1

# AWS location without spaces (e.g. eu-central-1)
export TF_VAR_aws_region=${AWS_DEFAULT_REGION}

## Installation-specific configuration

# Must be unique in the AWS account above used to store state
export TF_VAR_cluster_name=

# The provider of the installation (e.g. ionos)
export TF_VAR_provider_name=

# Base domain
export TF_VAR_base_domain=${TF_VAR_cluster_name}.${TF_VAR_provider_name}.vmware.gigantic.io

## VMWare installations use Route53 hosted zones in the
## AWS account listed above.

export TF_VAR_dns_use_route53=true

# ID of aws route53 zone
export TF_VAR_root_dns_zone_id=

## Network config for the MC

# CIDR for Management Cluster VPC
export TF_VAR_management_cluster_cidr=""

# management cluster subnet configuration
export TF_VAR_public_ip_address=""
export TF_VAR_dns_addresses='["",""]'

# NSX-T configuration
# export TF_VAR_nsxt_enabled= # default is false
export TF_VAR_nsxt_host=""
export TF_VAR_nsxt_username=""
export TF_VAR_nsxt_password=""

export TF_VAR_nsxt_edge_cluster=""
export TF_VAR_nsxt_tier0_gateway=""
export TF_VAR_nsxt_tier1_gateway=""
export TF_VAR_nsxt_transport_zone=""

# CIDR for bastion subnet
export TF_VAR_bastion_subnet_cidr=""

# Number of bastions to provision (defaults to 1)
export TF_VAR_bastion_host_count=""

# vSphere configuration

export TF_VAR_vsphere_server=""
export TF_VAR_vsphere_user=""
export TF_VAR_vsphere_password=""

export TF_VAR_vsphere_datacenter=""
export TF_VAR_vsphere_datastore=""
export TF_VAR_vsphere_compute_cluster=""
export TF_VAR_vsphere_template=""
export TF_VAR_vsphere_folder=""

# Overwrite any parameters from "platforms/vmware/giantnetes/variables.tf" here.

terraform init -backend=true \
  -backend-config="bucket=${TF_VAR_cluster_name}-state" \
  -backend-config="key=terraform.tfstate" \
  -backend-config="dynamodb_table=${TF_VAR_cluster_name}-lock" \
  -backend-config="profile=${AWS_PROFILE}" \
  -backend-config="region=${TF_VAR_aws_region}" \
  ./
