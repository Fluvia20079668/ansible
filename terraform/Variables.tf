############################################
# AWS Configuration
############################################

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-north-1"
}

############################################
# EC2 Configuration
############################################

variable "ami_id" {
  description = "Amazon Linux 2023 AMI"
  type        = string
  default     = "ami-07fb0a5bf9ae299a4"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string
  default     = "subnet-022d77f082de78109"
}

variable "vpc_id" {
  description = "VPC ID for the EC2 instance"
  type        = string
  default     = "vpc-07f0ec8836bb93715"
}

variable "ecr_name" {
  description = "Existing ECR repository name"
  type        = string
  default     = "my-simple-app"
}

variable "public_key_path" {
  description = "Path to your local SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
