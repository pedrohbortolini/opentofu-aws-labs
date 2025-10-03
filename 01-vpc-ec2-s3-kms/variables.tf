variable "aws_region" {
  description = "The AWS region where the resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "The AWS profile to use for authentication"
  type        = string
}

variable "project_name" {
  description = "The name of the project, used to prefix resource names."
  type        = string
}

variable "instance_type" {
  description = "Instance type for an instance"
  type        = string
  default     = "t3.micro"

}

variable "bucket_name" {
  description = "Name for S3 Bucket"
  type        = string

}

