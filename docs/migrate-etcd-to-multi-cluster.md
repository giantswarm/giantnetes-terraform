# Migrate etcd into cluster

## prepare
* stop kubelet on all master machines
* stop etcd3.service on second and third master machine
* go to first master

## master0
Export envs to use etcdctl againts cluster:
```
unalias etcdctl
export ETCDCTL_CERT_FILE=/etc/kubernetes/ssl/etcd/client-crt.pem
export ETCDCTL_CA_FILE=/etc/kubernetes/ssl/etcd/client-ca.pem
export ETCDCTL_KEY_FILE=/etc/kubernetes/ssl/etcd/client-key.pem
export ETCDCTL_ENDPOINT=https://127.0.0.1:2379
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

## master1
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

## master2
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

