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

# -------------------------
# ECR Repository (create if missing)
# -------------------------
data "aws_ecr_repository" "existing" {
  count = 1
  name  = var.ecr_repo_name
}

resource "aws_ecr_repository" "app_repo" {
  count = length(data.aws_ecr_repository.existing) == 0 ? 1 : 0
  name  = var.ecr_repo_name
}

# -------------------------
# EC2 Key Pair
# -------------------------
data "aws_key_pair" "existing" {
  count    = 1
  key_name = var.key_pair_name
}

resource "tls_private_key" "ec2_key" {
  count     = length(data.aws_key_pair.existing) == 0 ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  count      = length(data.aws_key_pair.existing) == 0 ? 1 : 0
  key_name   = var.key_pair_name
  public_key = tls_private_key.ec2_key[0].public_key_openssh
}

# -------------------------
# Security Group
# -------------------------
data "aws_security_group" "existing" {
  count  = 1
  filter {
    name   = "group-name"
    values = ["app-sg"]
  }
}

resource "aws_security_group" "app_sg" {
  count       = length(data.aws_security_group.existing) == 0 ? 1 : 0
  name        = "app-sg"
  description = "Allow SSH and app traffic"

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

# -------------------------
# EC2 Instance
# -------------------------
resource "aws_instance" "app_server" {
  ami                    = "ami-06c39ed6b42908a36" # Amazon Linux 2 EU-North-1
  instance_type          = var.instance_type
  key_name               = length(aws_key_pair.deployer) > 0 ? aws_key_pair.deployer[0].key_name : var.key_pair_name
  vpc_security_group_ids = length(aws_security_group.app_sg) > 0 ? [aws_security_group.app_sg[0].id] : [data.aws_security_group.existing[0].id]
  associate_public_ip_address = true

  tags = {
    Name = "MyAppServer"
  }
}

# -------------------------
# Outputs
# -------------------------
output "ec2_public_ip" {
  value = aws_instance.app_server.public_ip
}

output "ecr_repository_uri" {
  value = length(aws_ecr_repository.app_repo) > 0 ? aws_ecr_repository.app_repo[0].repository_url : data.aws_ecr_repository.existing[0].repository_url
}

output "private_key_pem" {
  value     = length(tls_private_key.ec2_key) > 0 ? tls_private_key.ec2_key[0].private_key_pem : "Use existing key pair"
  sensitive = true
}

