provider "aws" {
  region = "eu-central-1"
}

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.53"
    }
  }

  #backend "s3" {
  #  bucket = "michaellutemp77777"
  #  key    = "terraform/s3/terraform.tfstate"
  #  region = "eu-central-1"
  #  encrypt = true
  #}
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "michaellutemp77777"

  tags = {
    Name        = "michael"
    Environment = "temp"
  }
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "enc_example" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
