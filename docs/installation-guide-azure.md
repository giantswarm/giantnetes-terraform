# Installation steps

## Prerequisites

Common:
- az cli installed and `az login` executed

### Create storage account for terraform state

```
export NAME="cluster5"
az group create -n ${NAME}-terraform -l westeurope

az storage account create \
  -n ${NAME}terraform \
  -g ${NAME}-terraform \
  --kind BlobStorage \
  --location westeurope \
  --sku Standard_RAGRS \
  --access-tier Cool

az storage container create \
  -n ${NAME}-state \
  --public-access off \
  --account-name ${NAME}terraform

az storage container create \
  -n ${NAME}-build \
  --public-access off \
  --account-name ${NAME}terraform
```

Get access key it will be needed in the next step.

```
az storage account keys list -g ${NAME}-terraform  --account-name ${NAME}terraform
```

### Create service principal

Create resource group for cluster. We need one to assign permissions.

```
az group create -n ${NAME} -l westeurope
```

Create service principal with permissions limited to resource group.

```
export SUBSCRIPTION_ID=$(az account list | jq '.[].id')
az ad sp create-for-rbac --name=${NAME}-sp --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${NAME}"
```

Please save these and storage credentials above in keepass (e.g. "<cluster name> azure host cluster credentials"). They will be needed in next step.

### Prepare terraform environment

```
mkdir -p build
cp -r examples/azure/example-build/* build
cd build
```

Replace `<cluster_name>` in `backend-cloud-config.tf` and `backend.tf` and make sure backend configuration linked properly.

```
cat ../platforms/azure/giantnetes/backend.tf
cat ../platforms/azure/giantnetes-cloud-config/backend.tf
```

Edit `envs.sh`. DO NOT PUT passwords and keys into `envs.sh` as it will be stored as plain text.

Command below will ask for:
- storage account access key
- service principal secret key

```
source envs.sh
```

NOTE: Reexecute `source envs.sh` everytime if opening new console.

## Install

Terraform has two separate manifests:
- platforms/azure/giantnetes - all cluster resources
- platforms/azure/giantnetes-cloud-config - manifest to generate compressed cloud-config (workaround for custom_data size limit)

Install consists two stages:
- Vault (only needed because we bootstrapping Vault manually)
- Kubernetes

Master and workers will be created with in the Vault stage and expectedly will fail (and recreated later). This is done to keep single Terraform state and simplify cluster management after installation. Master and workers will be reprovisioned with right configuration in the second state called Kubernetes.

### Stage: Vault

#### Pregenerate cloud-configs for master and workers (We just need files to be exist).

```
terraform init ../platforms/azure/giantnetes-cloud-config
terraform plan ../platforms/azure/giantnetes-cloud-config
terraform apply ../platforms/azure/giantnetes-cloud-config
```

#### Create Vault virtual machine and all other necessary resources

Answer "No" for copying state, we are using different keys for the state.

```
terraform init ../platforms/azure/giantnetes
terraform plan ../platforms/azure/giantnetes
terraform apply ../platforms/azure/giantnetes
```

It should create all cluster resources. Please note master and worker vms are created, but will fail. This is expected behaviour.

#### Provision Vault with Ansible

How to do that see [here](https://github.com/giantswarm/aws-terraform/blob/master/docs/install-g8s-on-aws.md#install-vault-with-hive-ansible)

When done make sure to update "TF_VAR_nodes_vault_token" in envs.sh with node token that was outputed by Ansible.

### Stage: Kubernetes

#### Regenenerate cloud-configs for master and workers

Generates script with compressed cloud-config contents.

```
source envs.sh
```

```
terraform init ../platforms/azure/giantnetes-cloud-config
terraform plan ../platforms/azure/giantnetes-cloud-config
terraform apply ../platforms/azure/giantnetes-cloud-config
```

#### Install master and workers

##### Delete vms manually

Delete master vm manually it will be recreated by terraform (workaround for [this bug](https://github.com/terraform-providers/terraform-provider-azurerm/issues/148)).

```
az vm delete -y -n master-0 -g $TF_VAR_cluster_name
az disk delete -y -n master-0-os -g $TF_VAR_cluster_name
```

Delete workers manually.

```
az vm delete -y --no-wait --ids $(az vm list -g $TF_VAR_cluster_name --query "[].id" -o tsv | grep worker)
```

Wait 5 minutes at least, while vms are deleling.

```
az disk delete -y --ids $(az disk list -g $TF_VAR_cluster_name --query "[].id" -o tsv | grep 'worker.*os')
```

##### Apply terraform

```
terraform init ../platforms/azure/giantnetes
terraform plan ../platforms/azure/giantnetes
terraform apply ../platforms/azure/giantnetes
```

## Upload variables and configuration

```
for i in envs.sh backend-cloud-config.tf backend.tf; do
  az storage blob upload --account-name ${NAME}terraform -c ${NAME}-build -n ${i} -f ${i}
done
```

## Deletion

Easiest way to delete whole cluster is to delete resource group.

```
az group delete -n <cluster name>
```

Delete service principal.
```
az ad sp list --output=table | grep <cluster name> | awk '{print $1}'
az ad sp delete --id <appid>
```

## Updating cluster

### Prepare variables and configuration.

```
mkdir build
cd build
```

```
for i in envs.sh backend-cloud-config.tf backend.tf; do
  az storage blob download --account-name ${NAME}terraform -c ${NAME}-build -n ${i} -f ${i}
done
```

### Regenerate cloud-config

```
terraform init ../platoforms/azure/giantnetes-cloud-config
terraform plan ../platforms/azure/giantnetes-cloud-config
terraform apply ../platforms/azure/giantnetes-cloud-config
```

### Apply latest state

```
terraform init ../platforms/azure/giantnetes
terraform plan ../platforms/azure/giantnetes
terraform apply ../platforms/azure/giantnetes
```

### Update master and workers

Please see above how to delete master/worker vms. After vm deleted latest state should be applied like above.

## Known issues

- [TF AzureRM: custom_data is not detected in virtual machine resource](https://github.com/terraform-providers/terraform-provider-azurerm/issues/148).
- [TF AzureRM: scale set always recreated](https://github.com/terraform-providers/terraform-provider-azurerm/issues/490).
- [Kubernetes: Azure provider does not support scale sets](https://github.com/kubernetes/kubernetes/issues/40913).
- [Calico IPAM and networking are not supported by Azure](https://github.com/projectcalico/calicoctl/issues/949#issuecomment-304546574)
