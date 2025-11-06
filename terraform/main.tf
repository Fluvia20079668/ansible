terraform {
  required_version = ">= 1.9.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 🔹 Create ECR repository
resource "aws_ecr_repository" "app_repo" {
  name = var.ecr_repo_name
}

# 🔹 Create EC2 key pair (if doesn't exist)
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.ec2_key.public_key_openssh
}

# 🔹 Security group for EC2
resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Allow inbound SSH and app traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8090
    to_port     = 8090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 🔹 EC2 Instance
resource "aws_instance" "app_server" {
  ami                    = "ami-06c39ed6b42908a36" # Amazon Linux 2 (EU North 1)
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = {
    Name = "MyAppServer"
  }
}

# 🔹 Outputs (must be at root level)
output "ec2_public_ip" {
  description = "Public IP of EC2"
  value       = aws_instance.app_server.public_ip
}

output "ecr_repository_uri" {
  description = "ECR repository URI"
  value       = aws_ecr_repository.app_repo.repository_url
}

output "private_key_pem" {
  description = "Private key for SSH access"
  value       = tls_private_key.ec2_key.private_key_pem
  sensitive   = true
}
