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

# 🔹 Use existing ECR repo if exists
data "aws_ecr_repository" "existing" {
  count = length([for r in [var.ecr_repo_name] : r if r != ""]) > 0 ? 1 : 0
  name  = var.ecr_repo_name
}

# 🔹 Create ECR repo if it doesn't exist
resource "aws_ecr_repository" "app_repo" {
  count = length(data.aws_ecr_repository.existing) == 0 ? 1 : 0
  name  = var.ecr_repo_name
}

# 🔹 Key pair (existing or new)
resource "tls_private_key" "ec2_key" {
  count     = var.use_existing_key ? 0 : 1
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  count      = var.use_existing_key ? 0 : 1
  key_name   = var.key_pair_name
  public_key = tls_private_key.ec2_key[0].public_key_openssh
}

# 🔹 Security group (existing or new)
data "aws_security_group" "existing_sg" {
  filter {
    name   = "group-name"
    values = ["app-sg"]
  }
}

resource "aws_security_group" "app_sg" {
  count       = length(data.aws_security_group.existing_sg) == 0 ? 1 : 0
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

# 🔹 Get Amazon Linux 2 latest AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 🔹 Get default subnet
data "aws_subnets" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# 🔹 EC2 Instance
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = element(data.aws_subnets.default.ids, 0)
  key_name               = var.use_existing_key ? var.key_pair_name : aws_key_pair.deployer[0].key_name
  vpc_security_group_ids = [length(aws_security_group.app_sg) > 0 ? aws_security_group.app_sg[0].id : data.aws_security_group.existing_sg[0].id]
  associate_public_ip_address = true

  tags = {
    Name = "my-simple-app-server"
  }
}

# 🔹 Outputs
output "ec2_public_ip" {
  description = "Public IP of EC2"
  value       = aws_instance.app_server.public_ip
}

output "ecr_repository_uri" {
  description = "ECR repository URI"
  value       = length(aws_ecr_repository.app_repo) > 0 ? aws_ecr_repository.app_repo[0].repository_url : data.aws_ecr_repository.existing[0].repository_url
}

output "private_key_pem" {
  description = "Private key for SSH access"
  sensitive   = true
  value       = var.use_existing_key ? "Use existing key pair" : tls_private_key.ec2_key[0].private_key_pem
}
