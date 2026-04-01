terraform {
  backend "s3" {
    bucket         = "myproject-tf-state-YOUR_ACCOUNT_ID"  # ← your bucket name here
    key            = "prod/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "tf-lock"
    encrypt        = true
  }
}