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
RELEASE_VERSION=${RELEASE_VERSION:-v3.5.1}
export TF_VAR_release_version=${RELEASE_VERSION}
git fetch --all --tags
git checkout ${RELEASE_VERSION} || return

# opsctl path
OPSCTL_PATH=${OPSCTL_PATH:-opsctl}

# This file overrides terraform.tfvars values.
export AWS_PROFILE=<aws profile name>
export AWS_DEFAULT_REGION=<aws region>

# aws account ID
export TF_VAR_aws_account=<aws account id>

# aws location without spaces (e.g. eu-central-1)
export TF_VAR_aws_region=${AWS_DEFAULT_REGION}

# needs to be unique within the aws account
export TF_VAR_cluster_name=<cluster name>

# Precreated AWS customers gateways. Leave blank to disable VPN setup (bastions with public ips).
export TF_VAR_aws_customer_gateway_id_0=<e.g. cgw-xxxxxxx>
export TF_VAR_aws_customer_gateway_id_1=<e.g. cgw-xxxxxxx>

#Base domain.
export TF_VAR_base_domain=${TF_VAR_cluster_name}.${TF_VAR_aws_region}.aws.gigantic.io

# ID of aws route53 zone.
export TF_VAR_root_dns_zone_id=<aws route53 zone id>

# CIDR for Management Cluster VPC
export TF_VAR_vpc_cidr='<mc vpc cidr>'
export TF_VAR_subnets_bastion='["<gridscale /28>","<vultr /28>"]'
export TF_VAR_subnets_vault='["<vault /28>"]'
export TF_VAR_subnets_elb='["<first elb /27>","<second elb /27>","<third elb /27>"]'
export TF_VAR_subnets_worker='["<first worker/28>","<second worker /28>","<third worker/28>"]'

# Overwrite any parameters from "platforms/aws/giantnetes/variables.tf" here.

terraform init -backend=true \
-backend-config="bucket=${TF_VAR_cluster_name}-state" \
-backend-config="key=terraform.tfstate" \
-backend-config="dynamodb_table=${TF_VAR_cluster_name}-lock" \
-backend-config="profile=${TF_VAR_cluster_name}" \
-backend-config="region=${TF_VAR_aws_region}" \
 ./
