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

## Stages

### Common stage

Creates:
- resource group
- dns zone and propagates new zone in root dns zone

```
terraform workspace new stage-common
```

```
terraform init ../../platforms/azure/stage-common
terraform plan ../../platforms/azure/stage-common
terraform apply ../../platforms/azure/stage-common
```

TBD
