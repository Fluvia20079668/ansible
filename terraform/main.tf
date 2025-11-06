############################################
# PROVIDER & TERRAFORM CONFIG
############################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.aws_region
}

############################################
# DATA SOURCES
############################################

# Use existing VPC and Subnet
data "aws_vpc" "selected" {
  id = "vpc-07f0ec8836bb93715"
}

data "aws_subnet" "selected" {
  id = "subnet-022d77f082de78109"
}

# Reference existing ECR repository
data "aws_ecr_repository" "app" {
  name = var.ecr_name
}

############################################
# SECURITY GROUP
############################################

resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow SSH and App traffic"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow App Port"
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

  tags = {
    Name = "web-sg"
  }
}

############################################
# KEY PAIR
############################################

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file(var.public_key_path)
}

############################################
# EC2 INSTANCE
############################################

resource "aws_instance" "web_server" {
  ami                         = var.ami_id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  subnet_id                   = data.aws_subnet.selected.id
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y docker awscli
              systemctl enable docker
              systemctl start docker

              # Log in to ECR
              aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_ecr_repository.app.repository_url}

              # Pull and run app container
              docker pull ${data.aws_ecr_repository.app.repository_url}:latest
              docker run -d -p 8090:8090 --restart always ${data.aws_ecr_repository.app.repository_url}:latest
              EOF

  tags = {
    Name = "docker-web-server"
  }
}

############################################
# OUTPUTS
############################################

output "ec2_public_ip" {
  value = aws_instance.web_server.public_ip
}

output "app_url" {
  value = "http://${aws_instance.web_server.public_ip}:8090"
}

output "ecr_repository_uri" {
  value = data.aws_ecr_repository.app.repository_url
}
