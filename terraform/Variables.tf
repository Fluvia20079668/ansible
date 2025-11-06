# AWS region
variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
  default     = "eu-north-1"
}

# EC2 Key Pair name
variable "key_pair_name" {
  type        = string
  description = "Name of the EC2 Key Pair to use or create"
}

# ECR Repository name
variable "ecr_repo_name" {
  type        = string
  description = "Name of the ECR repository to use or create"
}

# EC2 instance type
variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t4g.micro"
}
