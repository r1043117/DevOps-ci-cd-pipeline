# This block tells Terraform which providers (cloud platforms) it needs to download
# Think of providers as plugins that let Terraform talk to different cloud services
terraform {
  required_providers {
    # We're using AWS as our cloud provider
    aws = {
      source  = "hashicorp/aws"  # Where to download the AWS plugin from
      version = "~> 5.0"          # Use version 5.x (the ~> means "5.0 or newer, but not 6.0")
    }
  }
}

# This block configures how to connect to AWS
# It will use the credentials you set up with 'aws configure'
provider "aws" {
  region = var.aws_region  # Which AWS region to create resources in (we'll define this variable later)
}
