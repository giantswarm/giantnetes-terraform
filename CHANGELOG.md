# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Bump to flatcar `3227.2.1`.
- Bump to kubernetes `1.23.9`.
- Bump to cilium app version `0.2.6`.
- Bump to coredns app version `1.11.0`.
- Bump to nginx-ingress-controller app version `2.15.1`.
- [AWS] Bump to aws-cloud-controller-manager app version `1.23.2-gs2`.
- [AWS] Bump to aws-ebs-csi-driver app version `2.16.1`.
- [Azure] Bump azure-cloud-controller-manager app to version `1.23.17-gs2`.
- [Azure] Bump azure-cloud-node-manager app to version `1.23.17-gs1`.
- [Azure] Bump azuredisk-ebs-driver app to version `1.21.0-gs1`.
- Enable `--allocate-node-cidrs` to controller-manager flags.
- Bump `azure-cloud-controller-manager` to `1.1.17-gs2`.

### Removed
- Remove k8s-addons code used to migrate to cilium.
- Remove calico-related files.

## [12.0.0] - 2022-07-18

### Fixed

- Fix runtime and image endpoint for crictl.

## [11.0.0] - 2022-07-12

### Added

- Enabled auditd on masters, workers and bastions.
- Add registry mirror setting for containerd.
- Add CiliumLocalRedirectPolicy for aad pod identity.

### Changed

- Bump flatcar to `3139.2.3`.
- Bump kubernetes to `1.22.11`.
- Bump `coredns` app to `1.10.1`.
- Bump `nginx-ingress-controller` app to `2.14.0`.
- [AWS] Bump `aws-ebs-csi-driver` to `2.15.0`.
- [AWS] Bump `aws-node-termination-handler` to `1.16.5-gs1`.
- [AWS] Bump `aws-cloud-controller-manager` to `1.22.4-gs1`.
- [AWS] Bump `aws-attach-etcd-dep` to `0.4.0`.
- [Azure] Bump `azuredisk-csi-driver` to `1.19.0-gs1`.
- [Azure] Bump `azure-cloud-controller-manager` to `1.1.17-gs1`.
- [Azure] Bump `azure-cloud-node-manager` to `1.1.17-gs1`.
- Switch from `calico` and `kube-proxy` to `Cilium`.

### Removed

- Don't create priority classes any more (chart-operator does that now).

### Fixed

- Bump etcd image version to 3.5.4 for etcd3-defrag unit.

### Removed

- Don't create priority classes any more (chart-operator does that now).

## [10.2.0] - 2022-06-29

### Changed

- Use containerd socket instead of dockershim in the kubelet config.
- [AWS] Bump to AWS-cni 1.11.2 and mount containerd socket instead of dockershim one to `aws-node` pods.
- Bump Pod Infra image to `giantswarm/pause-amd64:3.3`.

## [10.1.0] - 2022-06-23

### Added

- Add new variable `disable_api_fairness` to allow disabling API fairness.

## [10.0.1] - 2022-06-09

### Changed

- Bump `nginx-ingress-controller-app` to `2.12.1`.

## [10.0.0] - 2022-06-08

### Changed

- [Azure] Bump kubernetes to version 1.22.10.
- [Azure] Bump flatcar to version 3139.2.1.
- [AWS] Bump kubernetes to version 1.22.10.
- [AWS] Bump flatcar to version 3139.2.2.
- Bump etcd to 3.5.4.

## [9.4.0] - 2022-05-24

### Changed

- Switch kubelet's `cgroupDriver` to `systemd`.
- Bump `nginx-ingress-controller-app` to `2.12.0`.
- Rename eth1 config file to prevent Flatcar bug.

## [9.3.0] - 2022-05-09

### Changed

- [AWS] Disable kernel route for eth1 interface to avoid routing trouble within AZ.
- Bind Api Server to 0.0.0.0.
- Remove Api Server advertise address to make it be automatic set to VM's default IP address.

## [9.2.0] - 2022-05-05

### Changed

- [AWS] Switch to external cloud-controller-manager and CSI driver.
- [AWS] Bump flatcar to `3139.2.0`.

## [9.1.0] - 2022-05-03

### Changed

- Bump `nginx-ingress-controller-app` to `2.11.0`.
- Add `logs:*` permission to masters' IAM role to allow running fluentbit on master nodes.

## [9.0.0] - 2022-04-19

### Changed

- [Azure] Disable cloud-provider integration from core k8s components.
- [Azure] Add apps for out-of-tree cloud provider integration.
- [Azure] Switch to CSI storage provider.
- [Azure] Enable `CSIMigration` and `CSIMigrationAzureDisk` feature gates.
- [Azure] Bump flatcar to `3139.2.0`.
- Bump coredns to `1.9.0`.
- Bump nginx-ingress-controller to `2.10.0`.

## [8.4.1] - 2022-03-30

### Fixed

- Ignore AZ setting for public API LB on azure to avoid unsolvable conflict.

## [8.4.0] - 2022-03-30

### Added

- Allow setting custom tags to all resources in Azure.

## [8.3.0] - 2022-03-29

### Changed

- Bump azurerm provider to 3.0.2.
- Switch to Manual rolling mode for azure nodes.

## [8.2.0] - 2022-03-28

### Changed

- Create /srv/apps/ directory with all `App` CR manifests in order to simplify `k8s-addons` script.
- Bump azure-scheduled-events app to 0.7.0.
- Bump aws-node-termination-handler-app to 0.2.0.
- Bump kubernetes to `1.21.11`.
- Bump Flatcar to `3033.2.4`.
- Set `fs.inotify.max_user_instances` to 1024 to avoid `Too many open files` error.

## [8.1.0] - 2022-03-10

### Added

- Add `--tls-cipher-suites` flag to api-server manifest to disable vulnerable ciphers.

## [8.0.0] - 2022-03-01

### Added

- Enable lifecycle hooks to drain nodes before termination on AWS.

## [7.0.1] - 2022-02-24

### Fixed

- Fix max size of ASGs.

## [7.0.0] - 2022-02-24

### Changed

- Split worker nodes in different ASGs, each one having a single availability zone to ease cluster-autoscaler's decisions.

## [6.6.0] - 2022-02-18

### Changed

- Lock `azurerm` to version `2.96.0` to avoid upstream bug.

## [6.5.0] - 2022-02-17

### Changed

- Switch Azure Master nodes to `azurerm_linux_virtual_machine_scale_set`.
- Enable azure-scheduled-events for azure masters.

## [6.4.0] - 2022-02-11

### Changed

- Enable azure-scheduled-events for azure workers.

## [6.3.0] - 2022-02-10

### Changed

- Bump nginx ingress controller app to 2.9.0 and enable `enable-ssl-chain-completion` flag.

## [6.2.2] - 2022-02-07

### Fixed

- Set service CIDR and service IP for Coredns app.

## [6.2.1] - 2022-02-07

### Added

- Set clusterDomain in coredns config.

## [6.2.0] - 2022-02-04

### Added

- Allow customizing clusterDomain setting in kubelet.

## [6.1.1] - 2022-02-01

### Fixed

- Use PodCIDR instead of whole VNET CIDR for azure SNAT.

## [6.1.0] - 2022-02-01

### Changed

- Remove migration commands from k8s-addons (was needed to upgrade from < 6 to 6.0.0).

## [6.0.1] - 2022-01-31

### Fixed

- Fix CIDR in Azure CNI masquerading unit.

## [6.0.0] - 2022-01-28

### Changed

- Switch Azure Load Balancer to be Standard rather than Basic.
- Switch Azure from using calico for CNI to Calico with user provided routes.
- Move Ingress ELB resources in own module (AWS).
- Use managed app to deploy nginx ingress controller (AWS and Azure).
- Use managed app to deploy coredns (AWS and Azure).
- Bump flatcar to 3033.2.0 (AWS and Azure).
- Bump policy-only manifests to calico 3.21.3 (AWS and Azure).
- Bump etcd to 3.4.18 (AWS).
- Bump kubernetes to 1.21.9  (AWS and Azure).

## [5.10.0] - 2022-01-19

### Changed

- Temporarily re-enable ssh-rsa CASignatureAlgorithm in sshd until it is fully removed

## [5.9.0] - 2022-01-18

### Changed

- In azure, force service principal credentials to be explicitely set.

## [5.8.1] - 2022-01-05

## [5.8.0] - 2022-01-05

### Updated

- Updated version of `flatcar`, `aws-cni` and `kubernetes` for AWS.

## [5.7.1] - 2021-12-24

## [5.7.0] - 2021-12-15

### Changed

- Update `aws-cni` version from `1.7.5` to `1.9.3`.

### Fixed

- Limited hostnetwork pods to the daemonsets only when calculating max pods

## [5.6.0] - 2021-12-15

### Changed

- Revert flatcar to 2765.2.2 for AWS and Azure.

## [5.5.0] - 2021-12-15

### Changed

- Bump flatcar to 2983.2.0 for AWS and Azure.
- Bump Kubernetes to 1.20.13 for AWS and Azure.

### Fixed

- Correctly calculate the max pods for control plane nodes

## [5.4.0] - 2021-12-08

### Added

- Add AWS S3 bucket policy to allow only SSL access to the buckets.

## [5.3.2] - 2021-12-01

## [5.3.1] - 2021-12-01

## [5.3.0] - 2021-11-30

## [5.2.2] - 2021-11-25

## [5.2.1] - 2021-11-25

## [5.2.0] - 2021-11-24

### Added

- Add `additional_tags` variable to AWS in order to specify custom tags that will be applied to all resources.

## [5.1.0] - 2021-11-16

### Removed

- Remove AWS `vpn_instance` module. It was used for China regions and it's
  replaced with the Direct Connect setup.

### Changed

- Change Azure storage account authentication key (SAS) TTL to 180 days to comply with workload clusters.

## [5.0.0] - 2021-08-25

## [4.2.0] - 2021-08-24

### Changed

- Update `nginx-ingress-controller` to v0.33.0.
- Set `kernelMemcgNotification` kubelet flag to true. This helps better determine if memory eviction thresholds are crossed.
- Decrease `hostnetwork_pods` value for AWS CNI node pod limit script to 4.


## [4.1.0] - 2021-07-27

### Changed

- Enable SSL chain completion in `nginx-ingress-controller`.

## [4.0.1] - 2021-07-15

### Changed

- Fixed `/boot` automount udev rules for Azure storage devices

## [4.0.0] - 2021-06-23

### Fixed

- Add missing VGW attachment for AWS CN installations.

### Changed

- Include PE SSH keys on MC machines.

### Removed

- Remove unused `ami_owner` variable.
- Remove AWS CNI v1 subnets (remove `aws_cni_pod_cidrs` and `aws_cni_cidr_block` variables).

## [3.6.0] - 2021-06-14

### Changed

- Use VMSS instead of VMs for master nodes on Azure.
- Use 'Wants' instead of 'Requires' on key systemd units to make startup more reliable.

## [3.5.2] - 2021-05-17

### Changed

- Update nginx-IC to 0.29.0 and bring the specs closer to the ones in _nginx-ingress-controller-app_.

## [3.5.1] - 2021-04-23

### Fixed

- Removed oem dir mount unit on Azure. Feature is provided by Flatcar nowadays.

### Changed

- Move `--enable-server` kubelet flag to kubelet config file.

## [3.5.0] - 2021-04-08

### Added

- Expand audit logging.

### Changed

- Update Kubernetes to `1.20.5` version.
- Update Flatcar Linux to `2765.2.2` version.

## [3.4.0] - 2021-02-17

### Added

- Optional support for AzureManagedIdentity for Azure VMs.

## [3.3.1] - 2021-02-02

### Added

- Add `first_boot` file in bastion/master/worker ignition templates.

### Changed

- Allow access to bastion node-exporter metrics from pod CIDR.

## [3.3.0] - 2021-01-22

### Added

- Add systemd unit to retrieve Vault token.

### Changed

- Extend `vault` AWS IAM role with vault auth backend required access.
- Enable access to `vault` via node assigned identity in Azure.

## [3.2.0] - 2020-12-17

### Changed

- Increase maximum number of workers in AWS auto-scaling group.
- Extend master/worker IAM roles with cluster-autoscaler required access.
- Enable MSI on azure masters/workers instances.
- Add `Contributor` role assignement for masters/workers identities.

## [3.1.0] - 2020-12-14

### Added

- Add `cluster-autoscaler` tags for AWS ASG.
- Add `cluster-autoscaler` tags for Azure VMSS.

### Changed

- Switched to VMSS for Azure worker nodes.


## [3.0.0] - 2020-12-14

### Changed

- Change default timeouts for `create`/`delete` VM operations.
- Update terraform resources with `0.13.5` version requirements.
- Update `aws-cni` version from `1.7.2` to `1.7.5`.

## [2.2.0] - 2020-11-23

### Added

- Add labels for Kubernetes api-server pod.

### Changed

- Always configure Kubernetes API OIDC with dex issuer.

### Deleted

- Delete `route53_enabled` parameter as route53 now available in China.

## [2.1.1] - 2020-11-11

### Changed

- Reduce number of collectors used in `node-exporter` on bastion node.
- Use `aws-attach-etcd-dep:0.1.0` version in control plane.

## [2.1.0] - 2020-11-02

### Added

- Add `server-tokens: "false"` to Nginx Ingress Controller to remove the server tokens from the default backend response body and answer.

### Changed

- Changed default VM size for azure master nodes to Standard_D4s_v3.

### Deleted

- Delete Kubernetes API readonly role/binding.
- Update calico-policy-only deployment version to apps/v1

## [2.0.0] - 2020-10-26

### Changed

- Change Kubernetes version to 1.18.10.
- Change etcd version to 3.4.13.

## Removed

- Remove kube-proxy resourceContainer deprecated config.

## [1.5.1] - 2020-10-09

## Changed

- Changed the ETCD disk size to 64Gb on azure to have a higher provisioned IOPS.

## [1.5.0] - 2020-10-09

### Added

- Support for accelerated networking on azure.

### Changed

- Bumped kubernetes to 1.17.12 on azure.

### Fixed

- Do not fail k8s-setup-network-env if docker pull fails.

## [1.4.0] - 2020-09-16

### Changed

- Update AWS CNI version to 1.7.2 and align manifests with upstream.
- Migrate AWS CNi subnets to bigger CGNAT ranges.

## [1.3.2] - 2020-09-10

### Added

- Add `giantswarm.io/route-table-type` tag to AWS RouteTables.
- Add explicit OIDC issuer url configuration.

## [1.3.1] - 2020-08-27

### Changed

- Expose docker metrics.
- Expose kube-proxy metrics.
- Expose calico metrics.

## [1.3.0] - 2020-08-18

### Changed

- Set `AWS_VPC_K8S_CNI_EXTERNALSNAT=false`, to fix communication with TCs.

### Fixed

- Restart `k8s-addons.service` on failure.

## [1.2.0] - 2020-08-07

### Added

- Add internal load balancer for Kubernetes API in Azure.

## [1.1.0] - 2020-08-05

### Changed

- Update Flatcar Linux version to `2512.2.1`.
- Set default worker count to *4*.
- Use `employees` repo to get a list of users for VMs provisioning.

## [1.0.5] - 2020-08-04

### Added

- Add `vault-token-reviewer` service account and cluster-role binding.

### Changed

- Avoid using the 'plan' option in the vault VM in Azure when CoreOS is still in use.

## [1.0.4] - 2020-08-03

### Fixed

- Wait longer for `calico-node` pods being ready.

## [1.0.3] - 2020-08-03

- Improve max-pod-limit for kubelet on AWS platform to work with AWS CNI limitations.

## [1.0.2] - 2020-07-27

### Added

- Run `node-exporter` on bastions.

## [1.0.1] - 2020-07-23

### Added

- Export `giantnetes-terraform` release version into `/etc/gs-release-version` file on master/worker filesystem.

### Fixed

- Fix ingress controller resource rename from daemonset to deployment.

## [1.0.0] - 2020-07-20

### Added

- Add github release workflows.

[Unreleased]: https://github.com/giantswarm/giantnetes-terraform/compare/v12.0.0...HEAD
[12.0.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v11.0.0...v12.0.0
[11.0.0]: https://github.com/giantswarm/giantswarm/compare/v10.2.0...v11.0.0
[10.2.0]: https://github.com/giantswarm/giantswarm/compare/v10.1.0...v10.2.0
[10.1.0]: https://github.com/giantswarm/giantswarm/compare/v10.0.1...v10.1.0
[10.0.1]: https://github.com/giantswarm/giantswarm/compare/v10.0.0...v10.0.1
[10.0.0]: https://github.com/giantswarm/giantswarm/compare/v9.4.0...v10.0.0
[9.4.0]: https://github.com/giantswarm/giantswarm/compare/v9.3.0...v9.4.0
[9.3.0]: https://github.com/giantswarm/giantswarm/compare/v9.2.0...v9.3.0
[9.2.0]: https://github.com/giantswarm/giantswarm/compare/v9.1.0...v9.2.0
[9.1.0]: https://github.com/giantswarm/giantswarm/compare/v9.0.0...v9.1.0
[9.0.0]: https://github.com/giantswarm/giantswarm/compare/v8.4.1...v9.0.0
[8.4.1]: https://github.com/giantswarm/giantswarm/compare/v8.4.0...v8.4.1
[8.4.0]: https://github.com/giantswarm/giantswarm/compare/v8.3.0...v8.4.0
[8.3.0]: https://github.com/giantswarm/giantswarm/compare/v8.2.0...v8.3.0
[8.2.0]: https://github.com/giantswarm/giantswarm/compare/v8.1.0...v8.2.0
[8.1.0]: https://github.com/giantswarm/giantswarm/compare/v8.0.0...v8.1.0
[8.0.0]: https://github.com/giantswarm/giantswarm/compare/v7.0.1...v8.0.0
[7.0.1]: https://github.com/giantswarm/giantswarm/compare/v7.0.0...v7.0.1
[7.0.0]: https://github.com/giantswarm/giantswarm/compare/v6.6.0...v7.0.0
[6.6.0]: https://github.com/giantswarm/giantswarm/compare/v6.5.0...v6.6.0
[6.5.0]: https://github.com/giantswarm/giantswarm/compare/v6.4.0...v6.5.0
[6.4.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v6.2.2...v6.4.0
[6.2.2]: https://github.com/giantswarm/giantnetes-terraform/compare/v6.2.1...v6.2.2
[6.2.1]: https://github.com/giantswarm/giantnetes-terraform/compare/v6.2.0...v6.2.1
[6.2.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v6.1.1...v6.2.0
[6.1.1]: https://github.com/giantswarm/giantnetes-terraform/compare/v6.1.0...v6.1.1
[6.1.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v6.0.1...v6.1.0
[6.0.1]: https://github.com/giantswarm/giantnetes-terraform/compare/v6.0.0...v6.0.1
[6.0.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v5.10.0...v6.0.0
[5.10.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v5.9.0...v5.10.0
[5.9.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v5.8.1...v5.9.0
[5.8.1]: https://github.com/giantswarm/giantnetes-terraform/compare/v5.8.0...v5.8.1
[5.8.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v5.7.1...v5.8.0
[5.7.1]: https://github.com/giantswarm/giantnetes-terraform/compare/v5.7.0...v5.7.1
[5.7.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v5.6.0...v5.7.0
[5.6.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v5.5.0...v5.6.0
[5.5.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v5.4.0...v5.5.0
[5.4.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v5.3.2...v5.4.0
[5.3.2]: https://github.com/giantswarm/giantnetes-terraform/compare/v5.3.1...v5.3.2
[5.3.1]: https://github.com/giantswarm/giantnetes-terraform/compare/v5.3.0...v5.3.1
[5.3.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v5.2.2...v5.3.0
[5.2.2]: https://github.com/giantswarm/giantnetes-terraform/compare/v5.2.1...v5.2.2
[5.2.1]: https://github.com/giantswarm/giantnetes-terraform/compare/v5.2.0...v5.2.1
[5.2.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v5.1.0...v5.2.0
[5.1.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v5.0.0...v5.1.0
[5.0.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v4.2.0...v5.0.0
[4.2.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v4.1.0...v4.2.0
[4.1.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v4.0.1...v4.1.0
[4.0.1]: https://github.com/giantswarm/giantnetes-terraform/compare/v4.0.0...v4.0.1
[4.0.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v3.6.0...v4.0.0
[3.6.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v3.5.2...v3.6.0
[3.5.2]: https://github.com/giantswarm/giantnetes-terraform/compare/v3.5.1...v3.5.2
[3.5.1]: https://github.com/giantswarm/giantnetes-terraform/compare/v3.5.0...v3.5.1
[3.5.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v3.3.1...v3.5.0
[3.3.1]: https://github.com/giantswarm/giantnetes-terraform/compare/v3.3.0...v3.3.1
[3.3.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v3.2.0...v3.3.0
[3.2.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v3.1.0...v3.2.0
[3.1.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v2.2.0...v3.0.0
[2.2.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v2.1.1...v2.2.0
[2.1.1]: https://github.com/giantswarm/giantnetes-terraform/compare/v2.1.0...v2.1.1
[2.1.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v1.5.1...v2.0.0
[1.5.1]: https://github.com/giantswarm/giantnetes-terraform/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v1.3.2...v1.4.0
[1.3.2]: https://github.com/giantswarm/giantnetes-terraform/compare/v1.3.1...v1.3.2
[1.3.1]: https://github.com/giantswarm/giantnetes-terraform/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/giantswarm/giantnetes-terraform/compare/v1.0.5...v1.1.0
[1.0.5]: https://github.com/giantswarm/giantnetes-terraform/compare/v1.0.4...v1.0.5
[1.0.4]: https://github.com/giantswarm/giantnetes-terraform/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/giantswarm/giantnetes-terraform/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/giantswarm/giantnetes-terraform/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/giantswarm/giantnetes-terraform/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/giantswarm/giantnetes-terraform/releases/tag/v1.0.0
