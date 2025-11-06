variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "eu-north-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Amazon Linux 2023 AMI"
  type        = string
  default     = "ami-07fb0a5bf9ae299a4"
}

variable "ecr_repo_name" {
  description = "ECR repository name"
  type        = string
  default     = "my-simple-app"
}
