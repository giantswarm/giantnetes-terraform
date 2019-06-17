# This file overrides terraform.tfvars values.
export AWS_PROFILE=<aws profile name>
export AWS_DEFAULT_REGION=<aws region>

# aws account ID
export TF_VAR_aws_account=<aws account id>

# aws location without spaces (e.g. eu-central-1)
export TF_VAR_aws_region=${AWS_DEFAULT_REGION}

# needs to be unique within the aws account
export TF_VAR_cluster_name=<cluster name>

# will be added within the installation process ('cluster token' output by hive bootstrapping)
export TF_VAR_nodes_vault_token=

# Precreated AWS customers gateways. Leave blank to disable VPN setup (bastions with public ips).
export TF_VAR_aws_customer_gateway_id_0=<e.g. cgw-xxxxxxx>
export TF_VAR_aws_customer_gateway_id_1=<e.g. cgw-xxxxxxx>

#Base domain.
export TF_VAR_base_domain=${TF_VAR_cluster_name}.${TF_VAR_aws_region}.aws.gigantic.io

# ID of aws route53 zone.
export TF_VAR_root_dns_zone_id=<aws route53 zone id>

# (Only for VPN case) Make sure bastion subnets do not intersect.
export TF_VAR_subnets_bastion='["<bastion subnet cidr 1>", "<bastion subnet cidr 2>"]'

# Overwrite any parameters from "platforms/aws/giantnetes/variables.tf" here.

terraform init -backend=true \
-backend-config="bucket=${TF_VAR_cluster_name}-state" \
-backend-config="key=terraform.tfstate" \
-backend-config="dynamodb_table=${TF_VAR_cluster_name}-lock" \
-backend-config="profile=${TF_VAR_cluster_name}" \
-backend-config="region=${TF_VAR_aws_region}" \
 ./
