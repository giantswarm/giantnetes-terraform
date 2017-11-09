# Installation steps (IN PROGRESS)

## Prerequisites

Common:
- az cli configured

## Prepare terraform environment

```
export CLUSTER_NAME='cluster1'
mkdir -p build/${CLUSTER_NAME}
cp -r examples/azure/* build/${CLUSTER_NAME}
cd build/${CLUSTER_NAME}
```

Edit `envs.sh`.

```
source envs.sh
```

## Install

### Vault stage

Creates:
- common resources (whole networking and bastions)
- Vault

```
terraform workspace new vault
```

```
terraform init ../../platforms/azure/010-stage-vault
terraform plan ../../platforms/azure/010-stage-vault
terraform apply ../../platforms/azure/010-stage-vault
```

Please proceed to Vault installation with Ansible.

### Cloud config generation stage

Generates script with compressed cloud-config contents.

```
terraform workspace new cc
```

```
terraform init ../../platforms/azure/015-stage-cloud-config
terraform plan ../../platforms/azure/015-stage-cloud-config
terraform apply ../../platforms/azure/015-stage-cloud-config
```

### Kubernetes stage

Creates:
- common resources (whole networking and bastions)
- Master
- Workers scale set

```
terraform workspace new kubernetes
```

```
terraform init ../../platforms/azure/020-stage-kubernetes
terraform plan ../../platforms/azure/020-stage-kubernetes
terraform apply ../../platforms/azure/020-stage-kubernetes
```

## Deletion

Easiest way to delete whole cluster is to delete resource group.

```
az group delete -n <cluster name>
```
