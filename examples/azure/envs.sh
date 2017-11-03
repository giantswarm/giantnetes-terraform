# This file overrides terraform.tfvars values.

# azure location without spaces (e.g. westeurope)
export TF_VAR_azure_location=<azure-location-for-the-hostcluster>
# needs to be unique within the azure account
export TF_VAR_cluster_name=<hostcluster-codename>

# example is a standard gigantic.io domain structure.
# pls don't change if this cluster is installed with gigantic.io
#
# if you'd like to configure a custom domain please only change
# TF_VAR_base_domain (replace "azure.gigantic.io" with the custom
# domain)
export TF_VAR_base_domain=${TF_VAR_cluster_name}.${TF_VAR_azure_location}.azure.gigantic.io
# hosted zone name, leave empty to setup DNS manually
export TF_VAR_root_dns_zone_name="azure.gigantic.io"

# will be added within the installation process
export TF_VAR_nodes_vault_token=

# Override here any option from platforms/azure/variables.tf
