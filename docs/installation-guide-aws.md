# Installation steps

## Prerequisites

Common:

- `aws` cli
- `terraform-provider-ct`. See [README.md](https://github.com/giantswarm/giantnetes-terraform/blob/master/README.md) for installation.

## Multi-master

By default terraform will create multi-master cluster with 3 master nodes, single master mode can be enabled by setting terraform variable `master_count=1` or export env variable `export TF_VAR_master_count=1`.

### Create S3 bucket and DynamoDB table for terraform state

```bash
export CLUSTER="cluster1"
export AWS_DEFAULT_REGION="eu-central-1"

# Make sure you have proper profile configured in .aws/config
export AWS_PROFILE=${CLUSTER}
```

Let's create the bucket for terraform state.

```bash
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

### Vault auto-unseal

Auto-unseal with [transit unseal](https://www.vaultproject.io/docs/configuration/seal/transit.html) is configured by default.

### Prepare terraform

```bash
cp -r examples/aws/* ./platforms/aws/giantnetes/
cd ./platforms/aws/giantnetes/
```

Now prepare `bootstrap.sh`.

#### Pre-create customer gateways

If the bastions need to be publicly routable then please skip this step.

Otherwise, you will need to create a CGW for each VPN connection in the AWS console. They should be named after the VPN (Gridscale/Vultr) and the default settings should be used. The CGW IDs should be added to `bootstrap.sh`.

The commands below can be run multiple times to output the ID (they won't create new CGWs in subsequent runs

For Gridscale:
```bash
aws ec2 create-customer-gateway --bgp-asn=65000 --type="ipsec.1" \
    --public-ip="185.102.95.187" \
    --tag-specifications='ResourceType=customer-gateway,Tags=[{Key=Name,Value=Giant Swarm Gridscale}]' \
    | jq '.CustomerGateway.CustomerGatewayId'
```

For Vultr:
```bash
aws ec2 create-customer-gateway --bgp-asn=65000 --type="ipsec.1" \
    --public-ip="95.179.153.65" \
    --tag-specifications='ResourceType=customer-gateway,Tags=[{Key=Name,Value=Giant Swarm Vultr}]' \
    | jq '.CustomerGateway.CustomerGatewayId'
```

#### Custom subnet requirements

If a customer has requested specific IP blocks for an installation then these can be overridden via `bootstrap.sh`. If not overridden, the defaults from `variables.tf` will be used.

* Control Plane:

Control planes should be given a `/24`:

```bash
export TF_VAR_vpc_cidr='172.30.33.0/24'
```

And any subnets for control plane components should exist inside the `vpc_cidr` subnet. E.g.:

```bash
export TF_VAR_subnets_bastion='["172.30.33.0/28","172.30.33.16/28"]'
export TF_VAR_subnets_elb='["172.30.33.32/27","172.30.33.64/27","172.30.33.96/27"]'
export TF_VAR_subnets_vault='["172.30.33.128/28"]'
export TF_VAR_subnets_worker='["172.30.33.144/28","172.30.33.160/28","172.30.33.176/28"]'

```

Note: the bastion subnets should form one contiguous `/27` (as this is the VPN encryption domain). This should not overlap with any other customer VPN CIDRs - see [VPN subnets](https://intranet.giantswarm.io/docs/support-and-ops/vpn-subnet-allocation/) for a list of ranges currently in use.

Care should also be taken that the subnets chosen for the control plane do not overlap with any other default subnets (see `aws cni`, `docker` and `k8s service` CIDRs).

AWS CNI pod CIDR needs to be from the same private block as VPC and needs one subnet per AZ (usually 3 - check the installation region). The sizing for subnet should be ideally atleast `/24` or `/25`. 
```
export TF_VAR_aws_cni_cidr_block=172.18.128.0/20
export TF_VAR_aws_cni_pod_cidrs='["172.18.0.0/24","172.18.1.0/24","172.18.2.0/24"]'
```

* Tenant Clusters:

IP blocks for each TC will be sliced from this CIDR:

```bash
export TF_VAR_ipam_network_cidr='172.16.0.0/16'
```

Once `bootstrap.sh` is complete, source it:

```bash
source bootstrap.sh
```

NOTE: **Reexecute `source bootstrap.sh` in every new console.**

### Route53 DNS zone setup

Giantnetes requires real DNS domain, so it's mandatory to have existing DNS zone.

#### Parent DNS zone in Route53

Set id of the zone in `TF_VAR_root_dns_zone_id` in `bootstrap.sh`.

#### Parent DNS zone outside Route53

Leave `TF_VAR_root_dns_zone_id` empty and make delegation [manually](http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/CreatingNewSubdomain.html#UpdateDNSParentDomain) after first `terraform apply`, when DNS zone will be created.

## Install

Install consists two stages:

- Vault (only needed because we bootstrapping Vault manually)
- Kubernetes

Masters and workers will be created within the Vault stage and expectedly will fail (and recreated later). This is done to keep single Terraform state and simplify cluster management after installation. Masters and workers will be reprovisioned with right configuration in the second state called Kubernetes.

### Stage: Vault

```bash
source bootstrap.sh
```

```bash
terraform plan ./
terraform apply ./
```

It should create all cluster resources. Please note masters and worker vms are created, but will fail. This is expected behaviour.

#### Configure IPsec

Use [this guide](https://github.com/giantswarm/vpn#aws-ipsec-configuration) to configure IPSec.

To get passphrase login to AWS console, switch to VPC service and open VPN connections. Select newly created VPN connection and click "Download configuration".

#### Provision Vault with Ansible

How to do that see [here](https://github.com/giantswarm/hive/#install-insecure-vault)

### Stage: Kubernetes

Recreate the new masters to complete cluster bootstrapping

```bash
source bootstrap.sh

```

```bash
terraform apply ./
```

## Upload variables and configuration

Create `terraform` folder in [installations repository](https://github.com/giantswarm/installations) under particular installation folder. Copy variables and configuration.

```bash
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

```bash
source bootstrap.sh
```

Before delete all resources, you could want to keep access logs.

```bash
aws s3 sync s3://$CLUSTER-access-logs .
```

```bash
terraform destroy ./
```

Then remove dynamodb lock table:

```bash
aws dynamodb delete-table --table-name ${CLUSTER}-lock
```

And finally delete the bucket `${CLUSTER}-state` from the AWS console (versioned buckets cannot be deleted using the AWS CLI)

## Enable access logs for state bucket

For enabling the access logs in the terraform state bucket, modify the placeholders in `examples/logging-policy.json`
(For convention use `<cluster-name>-state-logs` as prefix).

```bash
aws s3api put-bucket-logging --bucket $CLUSTER-state --bucket-logging-status file://examples/logging-policy.json
```

## Updating cluster

### Prepare variables and configuration.

```bash
cd platforms/aws/giantnetes
```

```bash
export NAME=cluster1
export INSTALLATIONS=<installations_repo_path>

cp ${INSTALLATIONS}/${CLUSTER}/terraform/* .
```

```bash
source bootstrap.sh
```

### Apply latest state

Check resources that has been changed.

```bash
source bootstrap.sh
```

```bash
terraform plan ./
terraform apply ./
```

### Update masters

If you want to update only single master run:

```bash
id=MASTER_NUM
terraform apply -auto-approve -target="module.master.aws_launch_configuration.master[${id}]" -target="module.master.aws_cloudformation_stack.master_asg[${id}]" -target="module.master.aws_s3_bucket_object.ignition_master_with_tags[${id}]" ./
```

Update all masters at once ( there will soem some k8s api donwtime)

```bash
terraform apply ./
```

### Vault update

TBD

## Known issues

TBD

## Appendix A

Host cluster AWS VPC setup

![Giant Swarm AWS VPC setup](https://github.com/giantswarm/giantnetes-terraform/blob/master/docs/media/aws-vpc-setup.png?raw=true)
