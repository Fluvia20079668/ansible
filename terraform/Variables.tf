############################################
# AWS Configuration
############################################

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

############################################
# EC2 Configuration
############################################

variable "ami_id" {
  description = "Amazon Linux 2023 AMI for us-east-1"
  type        = string
  default     = "ami-0bdd88bd06d16ba03"
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
