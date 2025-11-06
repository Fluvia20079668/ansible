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

variable "ecr_name" {
  description = "Existing ECR repository name"
  type        = string
  default     = "my-simple-app"
}

variable "public_key_path" {
  description = "Absolute path to your local SSH public key (OpenSSH format)"
  type        = string
  default     = "/Users/michaeljames/.ssh/id_rsa.pub"  # Change to your absolute path
}
