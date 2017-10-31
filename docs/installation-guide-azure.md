# Installation steps (IN PROGRESS)

```
export CLUSTER_NAME='cluster1'
mkdir -p build/${CLUSTER_NAME}
cp -r examples/azure/* build/${CLUSTER_NAME}
```

Edit `build/${CLUSTER_NAME}/envs.sh`.

```
source build/${CLUSTER_NAME}/envs.sh
terraform init -backend-config=build/ant/backend.conf platforms/azure/stage-common
```

## Stages

### Common stage

Creates:
- resource group
- dns zone and propagates new zone in root dns zone

```
terraform plan platforms/azure/stage-common
```

```
terraform apply platforms/azure/stage-common
```

TBD
