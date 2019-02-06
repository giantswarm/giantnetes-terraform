# Guide how to migrate single CP to multi cluster

## before migration
do etcd backup of etcd cluster and shut down master right after that
```
ETCDCTL_API=3 etcdctl snapshot save db-snapshot --key=/etc/kubernetes/ssl/etcd/client-key.pem --cert=/etc/kubernetes/ssl/etcd/client-crt.pem --cacert=/etc/kubernetes/ssl/etcd/client-ca.pem --endpoints=https://etcd.MAIN_DOMAIN:2379
```
dont forget to copy the etcd snapshot out of the machien to somewhere safe


## Migration from old version
If you are migration from older version of giantnetes-terraform which did not have multi-master support please do following steps:

switch  `giantnetes-terraform` to branch `13bca31185e282a3ff65fcd523ecbef4057e2b36` and run:
```
terraform destroy -target=aws_cloudformation_stack.worker_asg -target=aws_instance.master --target=aws_elb.master --target=aws_elb.worker --target=aws_elb.vault --target=aws_subnet.elb_0 --target=aws_subnet.elb_1 --target=aws_subnet.worker_0 --target=aws_subnet.worker_1
```

## Apply new version
Be sure to be on latest master branch, have prepared build dir and be inside build dir:
```
source envs.sh
terraform apply ../platforms/aws/giantnetes/
```

## Migrate etcd into cluster

### prepare
* stop kubelet on all master machines
* stop all etcd's and  delete all etcd data via `rm -rf /var/lib/etcd/member` on all masters
```
sudo systemctl stop etcd3 k8s-kubelet
sudo rm -rf /var/lib/etcd/member
```
### master0
Copy the etcd snapshot backup on first master and restore data from etcd backup:
```
ETCDCTL_API=3 etcdctl snapshot restore  --data-dir="/tmp/etcd"  db-snapshot
sudo cp -r /tmp/etcd/member /var/lib/etcd/
sudo rm -rf /tmp/etcd/
sudo systemctl start etcd3
```


Export envs to use etcdctl againts cluster:
```
export ETCDCTL_CERT_FILE=/etc/kubernetes/ssl/etcd/client-crt.pem
export ETCDCTL_CA_FILE=/etc/kubernetes/ssl/etcd/client-ca.pem
export ETCDCTL_KEY_FILE=/etc/kubernetes/ssl/etcd/client-key.pem
export ETCDCTL_ENDPOINT=https://etcd1.DOMAIN_BASE:2379
```


Check member status via etcdctl and update member `peerURL`:
```
sudo -E etcdctl member list
sudo -E etcdctl member update MEMBER_ID https://etcd1.DOMAIN_BASE:2380
```


Add second master to etcd cluster
```
sudo -E etcdctl member add etcd2 https://etcd2.DOMAIN_BASE:2380
```

Now go to second master.

### master1
Edit `/etc/systemd/system/etcd3.service` and change `--initial-cluster-state new` to  to `--initial-cluster-state existing` and remove `etcd3=https://etcd3.DOMAIN_BASE:2379` from `--initial-cluster` in the same file. 

``` 
...
--initial-cluster-state new 
--initial-cluster=etcd1=https://etcd1.DOMAIN_BASE:2379,etcd2=https://etcd2.DOMAIN_BASE:2379,etcd3=https://etcd3.DOMAIN_BASE:2379
...
```
to
```
...
--initial-cluster-state existing
--initial-cluster=etcd1=https://etcd1.DOMAIN_BASE:2379,etcd2=https://etcd2.DOMAIN_BASE:2379
...
```

Save changes, reload systemd daemon and start etcd:
```
sudo vim /etc/systemd/system/etcd3.service
sudo systemctl daemon-reload
systemctl start etcd3
```

Now you should have 2 healthy nodes in etcd cluster, check logs on both masters or run:
```
sudo -E etcdctl cluster-health
```

### master2
Eedit /etc/systemd/system/etcd3.service and change `--initial-cluster-state new` to `--initial-cluster-state existing`.
```
sudo vim /etc/systemd/system/etcd3.service 
sudo systemctl daemon-reload
systemctl start etcd3
``` 

Now you should have 3 healthy nodes in etcd cluster, to ensure run:
```
sudo -E etcdctl cluster-health
```
## Recover rest of cluster
* Restart kubelets on all 3 masters to ensure everyhting is up and running.
* You might need to restart all workers so they properly register to k8s-api.
* On one of masters restart `k8s-addons` to esnure latest version is applied.
