# Guide how to migrate single CP to multi cluster
This migration will cause downtime for the cluster.

do etcd backup of etcd cluster and shut down master right after that
```
ETCDCTL_API=3 etcdctl snapshot save db-snapshot --key=/etc/kubernetes/ssl/etcd/client-key.pem --cert=/etc/kubernetes/ssl/etcd/client-crt.pem --cacert=/etc/kubernetes/ssl/etcd/client-ca.pem --endpoints=https://127.0.0.1:2379
```
Do not forget to copy the etcd snapshot out of the machine to somewhere safe.


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

