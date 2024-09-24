terraform {
  backend "s3" {
    bucket = "ajay-shakapuram-tf-automation"
    key = "eks/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "Terraform_statelock"
  }
}
  
