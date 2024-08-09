terraform {
  backend "s3" {
    bucket                  = "terraform-s3-state-2024-devops"
    key                     = "devopsUP"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  region = "ap-southeast-1"
}
