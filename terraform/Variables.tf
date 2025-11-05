############################################
# AWS Configuration
############################################
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-north-1"
}

############################################
# SSH Key Configuration
############################################
variable "public_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

############################################
# EC2 Configuration
############################################
variable "ami_id" {
  description = "Ubuntu 22.04 AMI for eu-north-1"
  type        = string
  default     = "ami-0989fb15ce71ba39e"
}

############################################
# ECR Repository Configuration
############################################
variable "ecr_name" {
  description = "Existing ECR repository name"
  type        = string
  default     = "my-simple-app"
}
