# Installation steps

## Prerequisites

Common:

- `az` cli installed (See [azure docs](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest))
- `az login` executed

If you have more than one subscription connected to your user, you have to login to the right one using:

`az login --tenant <directory group URL, i.e. accountgiantswarm.onmicrosoft.com>`

Based on the subscrtiption you want to work on, you might need to adjust the cloud name setting.
Run the following command to list subscriptions:

`az account list -o table`

Check the `CloudName` column on the subscription you want to work with and run the following command accordingly:

`az cloud set --name <CloudName got from command above, i.e. AzureGermanCloud>`

## Multi-master 
By default terraform will create multi-master cluster with 3 master nodes, single master mode can be enabled by setting terraform variable `master_count=1` or export env variable `export TF_VAR_master_count=1`.

### Create storage account for terraform state

```
export NAME="cluster1"
export REGION="westeurope"
az group create -n ${NAME}-terraform -l ${REGION}

az storage account create \
  -n ${NAME}terraform \
  -g ${NAME}-terraform \
  --kind BlobStorage \
  --location ${REGION} \
  --sku Standard_RAGRS \
  --access-tier Cool \
  --https-only true

az storage container create \
  -n ${NAME}-state \
  --public-access off \
  --account-name ${NAME}terraform

az storage container create \
  -n ${NAME}-build \
  --public-access off \
  --account-name ${NAME}terraform
  
az storage account blob-service-properties update \
  -g ${NAME}-terraform \
  --account-name ${NAME}terraform \
  --enable-versioning
```

Get access key it will be needed in the next step.

```
az storage account keys list -g ${NAME}-terraform  --account-name ${NAME}terraform
```

### Prepare terraform environment

```
cp -r examples/azure/* ./platforms/azure/giantnetes/
cd ./platforms/azure/giantnetes/
```

Edit `bootstrap.sh`. DO NOT PUT passwords and keys into `bootstrap.sh` as it will be stored as plain text.

Now update the `terraform-secrets.yaml` file with the azure credentials.

Set the storage account access key under the `Terraform.ArmAccessKey` key.
```
opsctl update secret --in=terraform-secrets.yaml -k Terraform.ArmAccessKey
```

If you need to setup a VPN (mandatory for production installations) you first need to get a /28 subnet unique for this installation.

Go to https://intranet.giantswarm.io/docs/support-and-ops/vpn-subnet-allocation/, choose an unused subnet and add it to the page with the new installation name to reserve it.

Generate a secret for the VPN:

```
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 50 | head -n 1
```

Then set it in the secrets file

```
opsctl update secret --in=terraform-secrets.yaml -k Terraform.VPNSharedKey
```

Finally, set the following variables in the `bootstrap.sh` file:

```
export TF_VAR_vpn_enabled=1
export TF_VAR_vpn_shared_key=$(${OPSCTL_PATH} show secret -i ./terraform-secrets.yaml -k Terraform.VPNSharedKey)
export TF_VAR_vpn_right_gateway_address_0=<ip address of first IPSec server (copy this from other installations in the installations repo)>
export TF_VAR_vpn_right_gateway_address_1=<ip address of second IPSec server (copy this from other installations in the installations repo)>
export TF_VAR_bastion_cidr=<the subnet you have chosen>
```

When you have finished editing the file, source it:

```
source bootstrap.sh
```

NOTE: Reexecute `source bootstrap.sh` everytime if opening new console.

## Install

Terraform has one manifest:

- platforms/azure/giantnetes - all cluster resources

Install consists two stages:

- Vault (only needed because we bootstrapping Vault manually)
- Kubernetes

### Stage: Vault

#### Create Vault virtual machine and all other necessary resources

```
source bootstrap.sh
```

```
terraform plan ./
terraform apply -target="module.dns" ./ 
terraform apply -target="module.vnet" -target="module.bastion" -target="module.vault" -target="module.vpn" ./
```

#### (Optional) Connect to VPN

If VPN is needed (mandatory on production installations) you need to update the VPN servers configuration.
Follow the instructions at the following page to update the VPN servers: https://github.com/giantswarm/vpn#configure-new-site2site-vpn-with-aws-installation

#### Provision Vault with Ansible

How to do that see [here](https://github.com/giantswarm/hive/#install-insecure-vault)

### Stage: Kubernetes

```
# Need to source the bootstrap.sh file again to read the new secret defined above.
source bootstrap.sh
terraform apply ./
```

### Complete Vault setup

Setup the Vault Kubernetes Auth backend by following [this guide](https://intranet.giantswarm.io/docs/support-and-ops/installation-guide-for-giantnetes/vault-kubernetes-auth-backend/).

## Upload variables and configuration

Create `terraform` folder in [installations repository](https://github.com/giantswarm/installations) under particular installation folder. Copy variables and configuration.

```
export INSTALLATIONS=<installations_repo_path>

mkdir -p ${INSTALLATIONS}/${NAME}/terraform
cp bootstrap.sh terraform-secrets.yaml ${INSTALLATIONS}/${NAME}/terraform/

cd ${INSTALLATIONS}
git checkout -b "${NAME}_terraform"
git add ${INSTALLATIONS}/${NAME}/terraform
git commit -S -m "Add ${NAME} terraform variables and configuration"
```

Create PR with related changes.

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
cd ./platforms/azure/giantnetes/
export NAME=cluster1
export INSTALLATIONS=<installations_repo_path>

cp ${INSTALLATIONS}/${CLUSTER}/terraform/* .
```

```
source bootstrap.sh
```

### Apply latest state

Check resources that has been changed.

```
terraform plan ./
```

#### Update masters

```
terraform taint module.master.azurerm_virtual_machine.master[0]
terraform apply -target=module.master ./

terraform taint module.master.azurerm_virtual_machine.master[1]
terraform apply -target=module.master ./

terraform taint module.master.azurerm_virtual_machine.master[2]
terraform apply -target=module.master ./
```

### Update everything else

```
terraform apply ./
```

NB: worker nodes will be rolled automatically and sequentially by Azure.

## Known issues

- [TF AzureRM: custom_data is not detected in virtual machine resource](https://github.com/terraform-providers/terraform-provider-azurerm/issues/148).
- [TF AzureRM: scale set always recreated](https://github.com/terraform-providers/terraform-provider-azurerm/issues/490).
- [Kubernetes: Azure provider does not support scale sets](https://github.com/kubernetes/kubernetes/issues/40913).
- [Calico IPAM and networking are not supported by Azure](https://github.com/projectcalico/calicoctl/issues/949#issuecomment-304546574)
