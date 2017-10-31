# This file overrides terraform.tfvars values.

# azure location without spaces (e.g. westeurope)
export TF_VAR_azure_location=<azure-location-for-the-hostcluster>
# needs to be unique within the azure account
export TF_VAR_cluster_name=<hostcluster-codename>

# example is a standard gigantic.io domain structure.
# pls don't change if this cluster is installed with gigantic.io
#
# if you'd like to configure a custom domain please only change
# TF_VAR_g8s_domain (replace "azure.gigantic.io" with the custom
# domain)
export TF_VAR_g8s_domain=${TF_VAR_cluster_name}.${TF_VAR_azure_location}.azure.gigantic.io
export TF_VAR_g8s_vault_dns=vault.${TF_VAR_g8s_domain}
export TF_VAR_g8s_api_dns=g8s.${TF_VAR_g8s_domain}
export TF_VAR_g8s_etcd_dns=etcd.${TF_VAR_g8s_domain}
export TF_VAR_g8s_ingress_dns=ingress.g8s.${TF_VAR_g8s_domain}
# hosted zone name, leave empty to setup DNS manually
export TF_VAR_root_dns_zone_name="azure.gigantic.io"

# will be added within the installation process
export TF_VAR_g8s_vault_token=

# Override here any option from platforms/azure/variables.tf
