# Installation steps

## Prerequisites

Common:
- `aws` cli
- `terraform-provider-ct`. See [Appendix A](#appendix-a) for installation.

### Create S3 bucket and DynamoDB table for terraform state

```
export CLUSTER="cluster1"
export AWS_DEFAULT_REGION="eu-central-1"

# Make sure you have proper profile configured in .aws/config
export AWS_PROFILE=${CLUSTER}
```

We need to create an extra bucket for saving all access logs.
So apart of the bucket to save the terraform state we will have a bucket for save
the access log entries of the aforementioned bucket and also the ignition bucket.

First, let's create the access log bucket. 
```
aws s3 mb s3://$CLUSTER-access-logs --region $AWS_DEFAULT_REGION

aws s3api put-bucket-encryption --bucket $CLUSTER-access-logs \
    --server-side-encryption-configuration \
        '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

After we need to grant permission to receive logs from the AWS delivery system.
```
aws s3api put-bucket-acl --bucket $CLUSTER-access-logs --grant-write URI=http://acs.amazonaws.com/groups/s3/LogDelivery --grant-read-acp URI=http://acs.amazonaws.com/groups/s3/LogDelivery
```

Finally, we want to enable also logging for the access logs bucket itself. In order to do that, 
modify placeholders in `examples/logging-policy.json` before create run the command (For convention use `self-access-logs` as prefix)
```
aws s3api put-bucket-logging --bucket $CLUSTER-access-logs --bucket-logging-status file://examples/logging-policy.json
```

Now, let's create the bucket for terraform state.
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

Before enable the logging in this bucket, modify the placeholders again in `examples/logging-policy.json`
(For convention use `<cluster-name>-state-logs` as prefix).
```
aws s3api put-bucket-logging --bucket $CLUSTER-state --bucket-logging-status file://examples/logging-policy.json
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

Edit `envs.sh`.

```
source envs.sh
```

NOTE: Reexecute `source envs.sh` in every new console.

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

```
export CLUSTER=cluster1

for i in envs.sh backend.tf provider.tf; do
  aws s3 cp ${i} s3://${CLUSTER}-state/${i}
done
```

## Deletion

```
source envs.sh
```

```
terraform init ../platforms/aws/giantnetes
terraform destroy ../platforms/aws/giantnetes
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
export CLUSTER=cluster1

for i in envs.sh backend.tf provider.tf; do
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

## Appendix A

`terraform-provider-ct` should be build from source code, because latest version 0.2 does not work properly with `passwd` section of ignition.
```
go get -u github.com/coreos/terraform-provider-ct
cp $GOPATH/bin/terraform-provider-ct ~/.terraform.d/plugins/linux_amd64/terraform-provider-ct
```
