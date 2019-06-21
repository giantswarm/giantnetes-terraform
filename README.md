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
