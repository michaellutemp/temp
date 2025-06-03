provider "aws" {
  region = local.region
}

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.53"
    }
  }

  backend "s3" {
    bucket = "michaellutemp77777"
    key    = "terraform/eks/terraform.tfstate"
    region = "eu-central-1"
    encrypt = true
  }

}
