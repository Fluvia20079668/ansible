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

  backend "local" {} # You can switch to S3 backend if needed
}

provider "aws" {
  region = var.aws_region
}

##############################
# SECURITY GROUP
##############################
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow SSH and App traffic"
  vpc_id      = data.aws_vpc.selected.id

  ingress = [
    {
      description      = "Allow App Port"
      from_port        = 8090
      to_port          = 8090
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "Allow SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress = [
    {
      description      = ""
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  tags = {
    Name = "web-sg"
  }
}

##############################
# FETCH DEFAULT VPC & SUBNET
##############################
data "aws_vpc" "selected" {
  default = true
}

data "aws_subnet" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  availability_zone = "${var.aws_region}a"
}

##############################
# KEY PAIR GENERATION
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
  subnet_id                   = data.aws_subnet.selected.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "terraform-web"
  }

  # Optional: simple user_data for testing webserver
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo service docker start
              docker run -d -p 8090:80 nginx
              EOF
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
