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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -------------------------
# VPC and Subnets
# -------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# -------------------------
# Key Pair: check if exists
# -------------------------
data "aws_key_pair" "existing" {
  for_each = toset([var.key_pair_name])
  key_name = each.value
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  count      = length([for k in data.aws_key_pair.existing : k if k.key_name == var.key_pair_name]) == 0 ? 1 : 0
  key_name   = var.key_pair_name
  public_key = tls_private_key.example.public_key_openssh
}

# -------------------------
# ECR Repository: check if exists
# -------------------------
data "aws_ecr_repository" "existing" {
  for_each       = toset([var.ecr_repo_name])
  name           = each.value
  depends_on     = [] # optional
  lifecycle      {
    ignore_changes = [image_tag_mutability]
  }
}

resource "aws_ecr_repository" "app_repo" {
  count = length([for r in data.aws_ecr_repository.existing : r if r.name == var.ecr_repo_name]) == 0 ? 1 : 0
  name  = var.ecr_repo_name
}

# -------------------------
# Security Group
# -------------------------
resource "aws_security_group" "ec2_sg" {
  name        = "ec2_security_group"
  description = "Allow HTTP and SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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
resource "aws_instance" "app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = element(data.aws_subnets.default.ids, 0)
  key_name                    = length(aws_key_pair.deployer) > 0 ? aws_key_pair.deployer[0].key_name : var.key_pair_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "my-simple-app"
  }
}

# Ubuntu AMI (latest)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# -------------------------
# Outputs
# -------------------------
output "ec2_public_ip" {
  value = aws_instance.app.public_ip
}

output "private_key_pem" {
  value     = length(aws_key_pair.deployer) > 0 ? tls_private_key.example.private_key_pem : "Use existing key pair"
  sensitive = true
}

output "ecr_repository_uri" {
  value = length(aws_ecr_repository.app_repo) > 0 ? aws_ecr_repository.app_repo[0].repository_url : var.ecr_repo_name
}
