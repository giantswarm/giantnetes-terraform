# Replace <cluster name> and <aws region> with proper values.
terraform {
  backend "s3" {
    bucket         = "<cluster name>-state"
    dynamodb_table = "<cluster name>-lock"
    key            = "terraform.tfstate"

    # Make sure to define profile in ~/.aws/config
    profile = "<cluster name>"
    region  = "<aws region>"
  }
}
