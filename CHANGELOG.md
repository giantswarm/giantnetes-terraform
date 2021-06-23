# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Add missing VGW attachment for AWS CN installations.

### Changed

- Include PE SSH keys on MC machines.

### Removed

- Remove unused `ami_owner` variable.

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

[Unreleased]: https://github.com/giantswarm/giantnetes-terraform/compare/v3.6.0...HEAD
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
