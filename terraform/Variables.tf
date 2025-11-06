variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
  default     = "ami-04b7b1c4371bda87b" # Amazon Linux 2 (EU-North-1)
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.micro"
}

variable "ecr_repo_name" {
  description = "ECR repository name"
  type        = string
  default     = "my-simple-app"
}
