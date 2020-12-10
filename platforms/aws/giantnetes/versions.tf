terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    gotemplate = {
      source = "giantswarm.io/operations/gotemplate"
    }
    http = {
      source = "hashicorp/http"
    }
    ignition = {
      source = "terraform-providers/ignition"
    }
  }
  required_version = ">= 0.13"
}
