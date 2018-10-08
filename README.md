[![CircleCI](https://circleci.com/gh/giantswarm/giantnetes-terraform.svg?style=shield)](https://circleci.com/gh/giantswarm/giantnetes-terraform)

# Giant Swarm control plane terraform manifests

Terraform manifests for installing Giant Swarm's control plane.

## Prerequisites
install terraform plugin: `terraform-provider-ct`
```
mkdir -p ${HOME}/.terraform.d/plugins/linux_amd64
go get -u github.com/coreos/terraform-provider-ct
ln -sf ${GOPATH}/bin/terraform-provider-ct ${HOME}/.terraform.d/plugins/linux_amd64/terraform-provider-ct
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
