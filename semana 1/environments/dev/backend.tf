terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "coderhouse-terraform-state-mauro-dev"
    key            = "pe1/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "coderhouse-terraform-locks"
    encrypt        = true
  }
}
