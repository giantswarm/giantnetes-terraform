# This file overrides terraform.tfvars values.
export AWS_PROFILE=<aws profile name>
export AWS_DEFAULT_REGION=<aws region>

# aws account ID
export TF_VAR_aws_account=<aws account id>

# aws location without spaces (e.g. eu-central-1)
export TF_VAR_aws_region=${AWS_DEFAULT_REGION}

# needs to be unique within the aws account
export TF_VAR_cluster_name=<cluster name>

# will be added within the installation process
export TF_VAR_nodes_vault_token=

# Precreated AWS customer gateway. Leave blank to disable VPN setup (bastions with public ips).
export TF_VAR_aws_customer_gateway_id=<e.g. cgw-xxxxxxx>

# Base domain.
export TF_VAR_base_domain=${TF_VAR_cluster_name}.${TF_VAR_aws_region}.aws.gigantic.io

# ID of aws route53 zone.
export TF_VAR_root_dns_zone_id=<aws route53 zone id>

# (Only for VPN case) Make sure bastion subnets do not intersect.
export TF_VAR_subnet_bastion_0=<bastion subnet cidr 1>
export TF_VAR_subnet_bastion_1=<bastion subnet cidr 2>

# Logging bucket expiration days
export TF_VAR_expiration_days=<expiration days>

# Overwrite any parameters from "platforms/aws/giantnetes/variables.tf" here.
