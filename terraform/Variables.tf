variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
  default     = "eu-north-1"
}

variable "key_pair_name" {
  default = "network"
}


variable "ecr_repo_name" {
  type        = string
  description = "Name of the ECR repository to use or create"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro" # x86_64 compatible
}
variable "use_existing_key" {
  description = "Set true if using existing EC2 key pair from AWS console"
  type        = bool
  default     = true
}
