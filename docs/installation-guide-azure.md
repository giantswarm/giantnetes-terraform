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
```

Get access key it will be needed in the next step.

```
az storage account keys list -g ${NAME}-terraform  --account-name ${NAME}terraform
```

### Create service principal

Create resource group for cluster. We need one to assign permissions.

```
az group create -n ${NAME} -l ${REGION}
```

Create service principal with permissions limited to resource group.

Get the subscription ID you want to work on by choosing the right "id" field from the following command:

```
az account list
```

```
export SUBSCRIPTION_ID=<the ID you found with the command above>
az ad sp create-for-rbac --name=${NAME}-sp --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${NAME}" --years 10
```

Please save these and storage credentials above in keepass (e.g. "<cluster name> azure host cluster credentials"). They will be needed in next step.

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

Set the service principal password under the `Terraform.AzureSPAadClientSecret` key.
```
opsctl update secret --in=terraform-secrets.yaml -k Terraform.AzureSPAadClientSecret
```

If you need to setup a VPN (mandatory for production installations) you first need to get a /28 subnet unique for this installation.

Go to https://github.com/giantswarm/giantswarm/wiki/Giant-Swarm-VPN, choose an unused subnet and add it to the page with the new installation name to reserve it.

Then, set the following variables in the `bootstrap.sh` file:

```
export TF_VAR_vpn_enabled=1
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
terraform apply -target module.vault.azurerm_virtual_machine.vault -target module.bastion.azurerm_virtual_machine.bastion ./
```

#### (Optional) Connect to VPN

If VPN was enabled, two additional manual steps are required:

1. Create VPN connection clients on Azure with a shared key you generate randomly.

```
export SHARED_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 50 | head -n 1)

echo $SHARED_KEY

az network vpn-connection create \
  -g ${NAME} \
  --name ${NAME}-vpn-connection-0 \
  --vnet-gateway1 ${NAME}-vpn-gateway \
  --local-gateway2 ${NAME}-vpn-right-gateway-0 \
  --shared-key $SHARED_KEY

az network vpn-connection create \
  -g ${NAME} \
  --name ${NAME}-vpn-connection-1 \
  --vnet-gateway1 ${NAME}-vpn-gateway \
  --local-gateway2 ${NAME}-vpn-right-gateway-1 \
  --shared-key $SHARED_KEY
```

2. Update the VPN connection 

Temporarily save the password generated somewhere, then follow the instructions at the following page to update the VPN servers: https://github.com/giantswarm/vpn#configure-new-site2site-vpn-with-aws-installation

#### Provision Vault with Ansible

How to do that see [here](https://github.com/giantswarm/hive/#install-insecure-vault)

### Stage: Kubernetes

```
source bootstrap.sh
```

#### Install master and workers

##### Taint machines so they are recreated

```
terraform taint "module.bastion.azurerm_virtual_machine.bastion[0]"
terraform taint "module.bastion.azurerm_virtual_machine.bastion[1]"
terraform taint "module.master.azurerm_virtual_machine.master[0]"
terraform taint "module.master.azurerm_virtual_machine.master[1]"
terraform taint "module.master.azurerm_virtual_machine.master[2]"
terraform taint "module.worker.azurerm_virtual_machine.worker[0]"
terraform taint "module.worker.azurerm_virtual_machine.worker[1]"
terraform taint "module.worker.azurerm_virtual_machine.worker[2]"
```

##### Apply terraform

**Always** answer "No" for copying state, we are using different keys for the state!

```
source bootstrap.sh
```

```
terraform plan ./
terraform apply ./
```

## Upload variables and configuration

Create `terraform` folder in [installations repositry](https://github.com/giantswarm/installations) under particular installation folder. Copy variables and configuration.

```
export CLUSTER=cluster1
export INSTALLATIONS=<installations_repo_path>

mkdir ${INSTALLATIONS}/${CLUSTER}/terraform
cp bootstrap.sh ${INSTALLATIONS}/${CLUSTER}/terraform/

cd ${INSTALLATIONS}
git checkout -b "${cluster}_terraform"
git add ${INSTALLATIONS}/${CLUSTER}/terraform
git commit -S -m "Add ${CLUSTER} terraform variables and configuration"
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
terraform taint -module="master" azurerm_virtual_machine.master.0
terraform apply ./

terraform taint -module="master" azurerm_virtual_machine.master.1
terraform apply ./

terraform taint -module="master" azurerm_virtual_machine.master.2
terraform apply ./
```

### Update workers

Select worker (e.g. last worker with index 3) for update and delete VM and OS disk as described [above](#delete-vms-manually).

```
terraform taint -module="worker" "azurerm_virtual_machine.worker.3"
terraform apply ./
```

Repeat for other workers.

### Update everything else

```
terraform apply ./
```

## Known issues

- [TF AzureRM: custom_data is not detected in virtual machine resource](https://github.com/terraform-providers/terraform-provider-azurerm/issues/148).
- [TF AzureRM: scale set always recreated](https://github.com/terraform-providers/terraform-provider-azurerm/issues/490).
- [Kubernetes: Azure provider does not support scale sets](https://github.com/kubernetes/kubernetes/issues/40913).
- [Calico IPAM and networking are not supported by Azure](https://github.com/projectcalico/calicoctl/issues/949#issuecomment-304546574)
