# Installation steps

## Prerequisites

Common:
- `aws` cli
- `terraform-provider-ct`. See [README.md](https://github.com/giantswarm/giantnetes-terraform/blob/master/README.md) for installation.

## Multi-master 
By default terraform will create multi-master cluster with 3 master nodes, single master mode can be enabled by setting terraform variable `master_count=1` or export env variable `export TF_VAR_master_count=1`.

### Create S3 bucket and DynamoDB table for terraform state

```
export CLUSTER="cluster1"
export AWS_DEFAULT_REGION="eu-central-1"

# Make sure you have proper profile configured in .aws/config
export AWS_PROFILE=${CLUSTER}
```

Let's create the bucket for terraform state.
```
aws s3 mb s3://$CLUSTER-state --region $AWS_DEFAULT_REGION

aws s3api put-bucket-versioning --bucket $CLUSTER-state \
    --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption --bucket $CLUSTER-state \
    --server-side-encryption-configuration \
        '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

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
cat ../platforms/aws/giantnetes/backend.tf
```

Put proper values in `provider.tf` and make sure provider configuration linked properly.

```
cat ../platforms/aws/giantnetes/provider.tf
```

Edit `envs.sh`.

```
source envs.sh
```
Useful links to avoid possible network overlapping [VPN subnets](https://github.com/giantswarm/giantswarm/wiki/Giant-Swarm-VPN)
NOTE: Reexecute `source envs.sh` in every new console.

### Configure ssh users

Add bastion users to `build/bastion-users.yaml`. All other vms take users configuration from `build/users.yaml`, so please modify it too.

### Route53 DNS zone setup

Giantnetes requires real DNS domain, so it's mandatory to have existing DNS zone.

#### Parent DNS zone in Route53

Set id of the zone in `TF_VAR_root_dns_zone_id` in `envs.sh`.

#### Parent DNS zone outside Route53

Leave `TF_VAR_root_dns_zone_id` empty and make delegation [manually](http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/CreatingNewSubdomain.html#UpdateDNSParentDomain) after first `terraform apply`, when DNS zone will be created.

## Install

Install consists two stages:
- Vault (only needed because we bootstrapping Vault manually)
- Kubernetes

Master and workers will be created within the Vault stage and expectedly will fail (and recreated later). This is done to keep single Terraform state and simplify cluster management after installation. Master and workers will be reprovisioned with right configuration in the second state called Kubernetes.

### Stage: Vault

```
terraform init ../platforms/aws/giantnetes
terraform plan ../platforms/aws/giantnetes
terraform apply ../platforms/aws/giantnetes
```

It should create all cluster resources. Please note master and worker vms are created, but will fail. This is expected behaviour.

#### Configure IPsec

Use [this guide](https://github.com/giantswarm/vpn#aws-ipsec-configuration) to configure IPSec.

To get passphrase login to AWS console, switch to VPC service and open VPN connections. Select newly created VPN connection and click "Download configuration".

#### Provision Vault with Ansible

How to do that see [here](https://github.com/giantswarm/aws-terraform/blob/master/docs/install-g8s-on-aws.md#install-vault-with-hive-ansible)

Set "TF_VAR_nodes_vault_token" in envs.sh with node token that was outputed by Ansible.

### Stage: Kubernetes

```
source envs.sh
```

```
terraform init ../platforms/aws/giantnetes
terraform plan ../platforms/aws/giantnetes
terraform apply ../platforms/aws/giantnetes
```

## Upload variables and configuration

Create `terraform` folder in [installations repositry](https://github.com/giantswarm/installations) under particular installation folder. Copy variables and configuration.

```
export CLUSTER=cluster1
export INSTALLATIONS=<installations_repo_path>

mkdir ${INSTALLATIONS}/${CLUSTER}/terraform
for i in envs.sh backend.tf provider.tf; do
  cp ${i} ${INSTALLATIONS}/${CLUSTER}/terraform/
done

cd ${INSTALLATIONS}
git checkout -b "${cluster}_terraform"
git add ${INSTALLATIONS}/${CLUSTER}/terraform
git commit -S -m "Add ${CLUSTER} terraform variables and configuration"
```

Create PR with related changes.


## Deletion

```
source envs.sh
```

Before delete all resources, you could want to keep access logs.

```
aws s3 sync s3://$CLUSTER-access-logs .
```

```
terraform init ../platforms/aws/giantnetes
terraform destroy ../platforms/aws/giantnetes
```


## Enable access logs for state bucket

For enabling the access logs in the terraform state bucket, modify the placeholders in `examples/logging-policy.json`
(For convention use `<cluster-name>-state-logs` as prefix).
```
aws s3api put-bucket-logging --bucket $CLUSTER-state --bucket-logging-status file://examples/logging-policy.json
```

## Updating cluster

### Prepare variables and configuration.

```
mkdir build
cd build
```

```
export NAME=cluster1
export INSTALLATIONS=<installations_repo_path>

cp ${INSTALLATIONS}/${CLUSTER}/terraform/* .
```

```
source envs.sh
```

### Apply latest state

Check resources that has been changed.

```
terraform init ../platforms/aws/giantnetes
terraform plan ../platforms/aws/giantnetes
terraform apply ../platforms/aws/giantnetes
```

### Update masters
As each master is single ec2 instance, normal `terraform apply` operation would cause all of 3 masters to go offline which is not desirable. In order to avoid that, master instance ignore changes by default. If you want to update them you need to taint each of them and then run `terraform apply` command:
```
# update first master
terraform taint --module="master" aws_instance.master.0
terraform apply ../platforms/aws/giantnetes

# update second master
terraform taint --module="master" aws_instance.master.1
terraform apply ../platforms/aws/giantnetes

# update third master
terraform taint --module="master" aws_instance.master.2
terraform apply ../platforms/aws/giantnetes

```


### Vault update

TBD

## Known issues

TBD

## Appendix A

Host cluster AWS VPC setup

![Giant Swarm AWS VPC setup](https://github.com/giantswarm/giantnetes-terraform/blob/master/docs/media/aws-vpc-setup.png?raw=true)

