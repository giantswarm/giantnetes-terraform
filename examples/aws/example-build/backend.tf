# Replace <cluster name> and <aws region> with proper values.
terraform {
  backend "s3" {
    bucket         = "<cluster name>-state"
    key            = "terraform.tfstate"
    region         = "<aws region>"
    dynamodb_table = "<cluster name>-lock"
  }
}
