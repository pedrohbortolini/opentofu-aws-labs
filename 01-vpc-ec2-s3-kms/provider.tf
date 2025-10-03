# This block defines core requirements for the OpenTofu/Terraform project.
terraform {
  # Enforces a minimum OpenTofu CLI version. Using >= 1.6.0 ensures compatibility
  # with all stable OpenTofu releases.
  required_version = ">= 1.6.0"

  # Declares the providers required for this configuration.
  required_providers {
    # Defines the AWS provider requirements.
    aws = {
      # Specifies the official source of the AWS provider in the public registry.
      source = "hashicorp/aws"

      # Sets a version constraint for the AWS provider. The "~>" operator allows
      # only patch-level updates within the specified minor version (e.g., 6.0.1, 6.0.2).
      version = "~> 6.0"
    }
  }
}

# This block configures the AWS provider, specifying how to authenticate and
# which region to deploy resources into.
provider "aws" {
  # The AWS region where the resources will be created.
  # The value is supplied dynamically through the 'aws_region' variable.
  region = var.aws_region

  # The named profile from the local AWS credentials file (~/.aws/credentials)
  # to use for authentication. This value is supplied by the 'aws_profile' variable.
  profile = var.aws_profile
}