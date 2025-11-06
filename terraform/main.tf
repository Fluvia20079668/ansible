terraform {
  required_version = ">= 1.5.0"

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

  backend "local" {} # Switch to S3 backend if needed
}

provider "aws" {
  region = var.aws_region
}

##############################
# DATA SOURCES
##############################
data "aws_vpc" "selected" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.selected.id
}

##############################
# SECURITY GROUP
##############################
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow SSH and App traffic"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "Allow App Port"
    from_port   = 8090
    to_port     = 8090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

##############################
# KEY PAIR
##############################
resource "tls_private_key" "deployer" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = tls_private_key.deployer.public_key_openssh
}

##############################
# EC2 INSTANCE
##############################
resource "aws_instance" "app_server" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.deployer.key_name
  subnet_id                   = data.aws_subnet_ids.all.ids[0]
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo systemctl enable docker
              sudo systemctl start docker
              docker run -d -p 8090:80 nginx
              EOF

  tags = {
    Name = "terraform-web"
  }
}

##############################
# ECR REPOSITORY
##############################
resource "aws_ecr_repository" "app" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

##############################
# OUTPUTS
##############################
output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "ecr_repository_uri" {
  description = "ECR repository URI"
  value       = aws_ecr_repository.app.repository_url
}

output "private_key_pem" {
  description = "Private key for connecting to EC2"
  value       = tls_private_key.deployer.private_key_pem
  sensitive   = true
}
