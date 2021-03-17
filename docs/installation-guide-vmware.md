# VMWare installations

## Terraform state

TF state for AWS installations is stored in the main GS account 

Export the cluster name:

```
export CLUSTER="cluster1"
```

Export the region (for VMWware installations this should always be `eu-central-1` for consistency):

```
export AWS_DEFAULT_REGION="eu-central-1"
```

Export the name of your AWS CLI profile used to access the main Giant Swarm AWS account:

```
export AWS_PROFILE=giantswarm
```

Create the TF state bucket and lock table:

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

### Prepare Terraform

```
cp -r examples/vmware/* ./platforms/vmware/giantnetes/
cd ./platforms/vmware/giantnetes/
```

Now configure `bootstrap.sh`. There should be no need to change the AWS account ID or region.

