# Installation steps

## Prerequisites

Common:
- `aws` cli

### Create S3 bucket and DynamoDB table for terraform state

```
export CLUSTER="cluster1"
export AWS_DEFAULT_REGION="eu-central-1"
```

```
aws s3 mb s3://$CLUSTER-state --region $AWS_DEFAULT_REGION

aws s3api put-bucket-versioning --bucket $CLUSTER-state \
    --versioning-configuration Status=Enabled

aws dynamodb create-table --region $AWS_DEFAULT_REGION \
    --table-name $CLUSTER-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

### Prepare terraform build directory

```
mkdir -p build
cp -r examples/aws/example-build/* build
cd build
```

Put proper values in `backend.tf` and make sure backend configuration linked properly.

```
cat ../platforms/azure/giantnetes/backend.tf
```

Edit `envs.sh`.

```
source envs.sh
```

NOTE: Reexecute `source envs.sh` in every new console.

## Install

Install consists two stages:
- Vault (only needed because we bootstrapping Vault manually)
- Kubernetes

Master and workers will be created with in the Vault stage and expectedly will fail (and recreated later). This is done to keep single Terraform state and simplify cluster management after installation. Master and workers will be reprovisioned with right configuration in the second state called Kubernetes.

### Stage: Vault

```
terraform init ../platforms/aws/giantnetes
terraform plan ../platforms/aws/giantnetes
terraform apply ../platforms/aws/giantnetes
```

It should create all cluster resources. Please note master and worker vms are created, but will fail. This is expected behaviour.

#### Provision Vault with Ansible

How to do that see [here](https://github.com/giantswarm/aws-terraform/blob/master/docs/install-g8s-on-aws.md#install-vault-with-hive-ansible)

Set "TF_VAR_nodes_vault_token" in envs.sh with node token that was outputed by Ansible.

### Stage: Kubernetes

```
source envs.sh
```

```
terraform init ../platforms/azure/giantnetes
terraform plan ../platforms/azure/giantnetes
terraform apply ../platforms/azure/giantnetes
```

## Upload variables and configuration

```
export CLUSTER=gauss

for i in envs.sh backend.tf; do
  aws s3 cp ${i} s3://${CLUSTER}-state/${i}
done
```

## Deletion

```
source envs.sh
```

```
terraform init ../platforms/azure/giantnetes
terraform destroy ../platforms/azure/giantnetes
```

Delete s3 bucket and dynamodb.

```
aws s3 rb s3://$CLUSTER-build
aws dynamodb delete-table --region $AWS_DEFAULT_REGION --table-name $CLUSTER-lock
```

## Updating cluster

### Prepare variables and configuration.

```
mkdir build
cd build
```

```
export CLUSTER=gauss

for i in envs.sh backend.tf; do
  aws s3 cp s3://${CLUSTER}-state/${i} ${i}
done
```

### Apply latest state

Check resources that has been changed.

```
terraform init ../platforms/aws/giantnetes
terraform plan ../platforms/aws/giantnetes
terraform apply ../platforms/aws/giantnetes
```

### Vault update

TBD

## Known issues

TBD
