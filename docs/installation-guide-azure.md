# Installation steps

## Prerequisites

Common:

- `az` cli installed (See [azure docs](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest))
- `az login` executed (To switch to German cloud `az cloud set --name AzureGermanCloud`)

## Multi-master 
By default terraform will create multi-master cluster with 3 master nodes, single master mode can be enabled by setting terraform variable `master_count=1` or export env variable `export TF_VAR_master_count=1`.

## Vault auto-unseal
In case Azure Cloud supports MSI (Managed Service Identities), `vault` can be provisioned with additional resources for `auto-unseal`. This process requires master key to be inside the Key Vault. `create key` operation requires respective access policy for the identity, which is running provisioning. Therefore, special `terraform` group should be created in the Active Directory for respective subscription:
  - group name: `terraform`
  - members: SREs, who can run terraform manually; `conveyor` service principal; e2e service principal in case of Giant Swarm subscription.

After group is created, `Object ID` value should be assigned for `TF_VAR_terraform_group_id` in `bootstrap.sh` file:
```
export TF_VAR_terraform_group_id=<group_id>
```

In case cloud doesn't support MSI (Azure Germany, Azure Stack etc), vault should be provisioned with [hive](https://github.com/giantswarm/giantnetes-terraform/blob/master/docs/installation-guide-azure.md#provision-vault-with-ansible<Paste>).

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
az group create -n ${NAME} -l ${REGION}
```

Create service principal with permissions limited to resource group.

```
export SUBSCRIPTION_ID=$(az account list | jq '.[0].id' | sed 's/\"//g')
az ad sp create-for-rbac --name=${NAME}-sp --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${NAME}" --years 10
```

Please save these and storage credentials above in keepass (e.g. "<cluster name> azure host cluster credentials"). They will be needed in next step.

### Prepare terraform environment

```
cp -r examples/azure/* ./platforms/azure/giantnetes/
cd ./platforms/aws/giantnetes/
```

Edit `bootstrap.sh`. DO NOT PUT passwords and keys into `bootstrap.sh` as it will be stored as plain text.

Command below will ask for:

- storage account access key
- service principal secret key

For German cloud add following two variables into `bootstrap.sh`

```
export ARM_ENVIRONMENT="german"
export TF_VAR_azure_cloud=AZUREGERMANCLOUD
```

Optionally for VPN support add following variables. `bastion_cidr` should be unique and a part of `vnet_cidr` (10.0.0.0/16 by default). Recommended to use /28 subnets from range 10.0.4.0/22 (e.g. 10.0.4.0/28, 10.0.4.16/28, etc.).

```
export TF_VAR_vpn_enabled=1
export TF_VAR_vpn_right_gateway_address_0=<ip address of first IPSec server>
export TF_VAR_vpn_right_gateway_address_1=<ip address of second IPSec server>
export TF_VAR_bastion_cidr=<bastion subnet>
```

```
bootstrap envs.sh
```

NOTE: Reexecute `source bootstrap.sh` everytime if opening new console.

### Configure ssh users

Add bastion users to `ignition/bastion-users.yaml`. All other vms take users configuration from `ignition/users.yaml`, so please modify it too.

## Install

Terraform has one manifest:

- platforms/azure/giantnetes - all cluster resources

Install consists two stages:

- Vault (only needed because we bootstrapping Vault manually)
- Kubernetes

Master and workers will be created with in the Vault stage and expectedly will fail (and recreated later). This is done to keep single Terraform state and simplify cluster management after installation. Master and workers will be reprovisioned with right configuration in the second state called Kubernetes.

### Stage: Vault

#### Create Vault virtual machine and all other necessary resources

**Always** answer "No" for copying state, we are using different keys for the state!

```
source bootstrap.sh
```

```
terraform plan ./
terraform apply ./
```

It should create all cluster resources. Please note master and worker vms are created, but will fail. This is expected behaviour.

#### (Optional) Connect to VPN

If VPN enabled, two additional manual steps are required:

1. Create Azure VPN connection with shared key.
2. Create new IPSec connection in onpremise VPN server.

For step one execute following commands.

```
az network vpn-connection create \
  -g ${NAME} \
  --name ${NAME}-vpn-connection-0 \
  --vnet-gateway1 ${NAME}-vpn-gateway \
  --local-gateway2 ${NAME}-vpn-right-gateway-0 \
  --shared-key <put_your_shared_key1_here>

az network vpn-connection create \
  -g ${NAME} \
  --name ${NAME}-vpn-connection-1 \
  --vnet-gateway1 ${NAME}-vpn-gateway \
  --local-gateway2 ${NAME}-vpn-right-gateway-1 \
  --shared-key <put_your_shared_key2_here>
```

Step two is individual and depends on your setup.

#### Provision Vault with Ansible

How to do that see [here](https://github.com/giantswarm/hive/#install-insecure-vault)

When done make sure to update "TF_VAR_nodes_vault_token" in bootstrap.sh with node token that was outputed by Ansible.

### Stage: Kubernetes

```
source bootstrap.sh
```

#### Install master and workers

##### Taint machines so they are recreated

```
terraform taint -module="bastion" "azurerm_virtual_machine.bastion.0"
terraform taint -module="bastion" "azurerm_virtual_machine.bastion.1"
terraform taint -module="master" "azurerm_virtual_machine.master.0"
terraform taint -module="master" "azurerm_virtual_machine.master.1"
terraform taint -module="master" "azurerm_virtual_machine.master.2"
terraform taint -module="worker" "azurerm_virtual_machine.worker.0"
terraform taint -module="worker" "azurerm_virtual_machine.worker.1"
terraform taint -module="worker" "azurerm_virtual_machine.worker.2"
terraform taint -module="worker" "azurerm_virtual_machine.worker.3"
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
