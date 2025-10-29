variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "azs" {
  description = "List of AZs"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "asg_min" {
  description = "ASG minimum size"
  default     = 1
}

variable "asg_desired" {
  description = "ASG desired size"
  default     = 1
}

variable "asg_max" {
  description = "ASG maximum size"
  default     = 2
}

variable "rds_instance_class" {
  description = "RDS instance class"
  default     = "db.t3.micro"
}

variable "db_user" {
  description = "RDS master username"
  default     = "masteruser"
}

variable "db_password" {
  description = "RDS master password"
  default     = "MySecurePwd_2025!"
}

variable "redis_node_type" {
  description = "Elasticache Redis node type"
  default     = "cache.t3.micro"
}

variable "bastion_cidr" {
  description = "Allowed CIDR for SSH"
  default     = "191.19.71.189/32"
}
