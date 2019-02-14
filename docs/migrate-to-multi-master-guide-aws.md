# Guide how to migrate single CP to multi cluster
This migration will cause downtime for the cluster.


## before migration
do etcd backup of etcd cluster and shut down master right after that
```
ETCDCTL_API=3 etcdctl snapshot save db-snapshot --key=/etc/kubernetes/ssl/etcd/client-key.pem --cert=/etc/kubernetes/ssl/etcd/client-crt.pem --cacert=/etc/kubernetes/ssl/etcd/client-ca.pem --endpoints=https://127.0.0.1:2379
```
Do not forget to copy the etcd snapshot out of the machine to somewhere safe.


## Migration from old version
If you are migration from older version of giantnetes-terraform which did not have multi-master support please do following steps:

### delete old infrastrucutre
switch  `giantnetes-terraform` to branch `13bca31185e282a3ff65fcd523ecbef4057e2b36` and run:
```
terraform destroy --target=aws_cloudformation_stack.worker_asg --target=aws_instance.master --target=aws_elb.master --target=aws_elb.worker --target=aws_elb.vault --target=aws_subnet.elb_0 --target=aws_subnet.elb_1 --target=aws_subnet.worker_0 --target=aws_subnet.worker_1 --target=aws_instance.bastion --target=aws_subnet.bastion_0 --target=aws_subnet.bastion_1 --target=aws_vpc_endpoint.cloudwatch --target=aws_nat_gateway.private_nat_gateway_0 --target=aws_nat_gateway.private_nat_gateway_1 --target=aws_eip.private_nat_gateway_0  --target=aws_eip.private_nat_gateway_1 --target=aws_vpc_endpoint.s3 --target=aws_route.vpc_route_0 --target=aws_route.vpc_route_1 --target=aws_launch_configuration.worker
```
after deletion go back to latest master

### update terraform values
There is change in subnet naming and structure. Subnets are agregated into lists and names are also changed: 
```
subnets_bastion = ["10.0.1.0/25", "10.0.1.128/25"]
subnets_elb = ["10.0.2.0/26", "10.0.2.64/26", "10.0.2.128/26"]
subnets_vault = ["10.0.3.0/25"]
subnets_worker = ["10.0.5.0/26", "10.0.5.64/26", "10.0.5.128/26"]
```

If the cluster is using custom worker subnet or elb subnet, than you need to adjust the values and add one more subnet. Old version worked with 2 worker subnets and 2 elb subnets, new version needs 3 subnets for both and in `list` format. This can be easily done by reducing the subnet size.

Old:
```
export TF_VAR_subnet_elb_0=10.0.0.0/25
export TF_VAR_subnet_elb_1=10.0.0.128/25
export TF_VAR_subnet_worker_0=10.0.1.0/25
export TF_VAR_subnet_worker_1=10.0.1.128/25
```
New:
```
export TF_VAR_subnets_elb='["10.0.0.0/26","10.0.0.64/26","10.0.0.128/26"]'
export TF_VAR_subnets_worker='["10.0.1.0/26","10.0.1.64/26","10.0.1.128/26"]'
```


## Apply new version
Be sure to be on latest master branch, have prepared build dir and be inside build dir:
```
source envs.sh
terraform apply ../platforms/aws/giantnetes/
```

## Migrate etcd into cluster

see [migrate to etcd multi cluster guide](https://github.com/giantswarm/giantnetes-terraform/blob/master/docs/migrate-etcd-to-multi-cluster.md)

## Recover rest of cluster
* Restart kubelets on all 3 masters to ensure everyhting is up and running.
* You might need to restart all workers so they properly register to k8s-api.
* On one of masters restart `k8s-addons` to esnure latest version is applied.

## Recover tenant cluster peering
If there are any cluster created with `aws-operator`, then the CloudFormation stack that is configuring VPC peering needs to be deleted in order to reconfigure proper connection between VPCs.

The CloudFormation stack name look like this: `cluster-{cluster_id}-host-main`. After deletion, `aws-operator` will recreate it with proper values.

