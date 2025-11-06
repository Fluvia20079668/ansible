variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-north-1"
}

variable "ami_id" {
  description = "Amazon Linux 2023 AMI"
  type        = string
  default     = "ami-07fb0a5bf9ae299a4"
}

variable "ecr_name" {
  description = "Existing ECR repository name"
  type        = string
  default     = "my-simple-app"
}
