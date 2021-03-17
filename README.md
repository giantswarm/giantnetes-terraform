[![CircleCI](https://circleci.com/gh/giantswarm/giantnetes-terraform.svg?style=shield)](https://circleci.com/gh/giantswarm/giantnetes-terraform)

# Giant Swarm control plane terraform manifests

Terraform manifests for installing Giant Swarm's control plane.

## Prerequisites
install terraform plugin: `terraform-provider-ct`
```
VERSION=v0.3.2
wget https://github.com/poseidon/terraform-provider-ct/releases/download/$VERSION/terraform-provider-ct-$VERSION-linux-amd64.tar.gz
tar xzf terraform-provider-ct-$VERSION-linux-amd64.tar.gz
mv terraform-provider-ct-$VERSION-linux-amd64/terraform-provider-ct ~/.terraform.d/plugins/terraform-provider-ct_$VERSION
```
install terraform plugin: `terraform-provider-gotemplate`
```
mkdir -p ${HOME}/.terraform.d/plugins/linux_amd64
go get -u github.com/giantswarm/terraform-provider-gotemplate
ln -sf ${GOPATH}/bin/terraform-provider-gotemplate ${HOME}/.terraform.d/plugins/linux_amd64/terraform-provider-gotemplate
```


## Installation


Please follow:
- [installation guide for AWS](docs/installation-guide-aws.md).
- [installation guide for Azure](docs/installation-guide-azure.md).
- [installation guide for VMWare](docs/installation-guide-vmware.md).


## Debug procedure

### Exported logs

The easiest way to debug issues in failed build, is enabling logs export into Logentries. 
This can be done via `.circleci/config.yaml` configuration by setting `LOGENTRIES_ENABLED: "true"`:

```
  e2eTestAzureMultiMaster: &e2eTestAzureMultiMaster
    docker:
      - image: quay.io/giantswarm/docker-terraform-and-stuff:latest
    environment:
      MASTER_COUNT: 3
      LOGENTRIES_ENABLED: "false"
    steps:
    - checkout
    - run: ./misc/e2e-azure.sh
```

Logs can be found in [Rapid7 Insight](https://insight.rapid7.com) platform under *Control Plane*/*Terraform CI* log set.
Credentials to *Rapid7 Insight* can be found in Keepass under *Logentries / Rapid7*.
