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
# Default VPC and Subnets
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
# Security Group
# -------------------------
data "aws_security_group" "existing_sg" {
  filter {
    name   = "group-name"
    values = ["ec2_security_group"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "ec2_sg" {
  count       = length([for sg in [try(data.aws_security_group.existing_sg, null)] : sg if sg == null])
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
# EC2 Key Pair
# -------------------------
data "aws_key_pair" "existing" {
  key_name = var.key_pair_name
}

resource "tls_private_key" "new_key" {
  count     = length([for k in [try(data.aws_key_pair.existing, null)] : k if k == null])
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  count      = length([for k in [try(data.aws_key_pair.existing, null)] : k if k == null])
  key_name   = var.key_pair_name
  public_key = tls_private_key.new_key[0].public_key_openssh
}

# -------------------------
# ECR Repository
# -------------------------
data "aws_ecr_repository" "existing" {
  name = var.ecr_repo_name
}

resource "aws_ecr_repository" "app_repo" {
  count = length([for r in [try(data.aws_ecr_repository.existing, null)] : r if r == null])
  name  = var.ecr_repo_name
}

# -------------------------
# EC2 Instance
# -------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = element(data.aws_subnets.default.ids, 0)
  key_name                    = length(aws_key_pair.deployer) > 0 ? aws_key_pair.deployer[0].key_name : var.key_pair_name
  vpc_security_group_ids      = [length(aws_security_group.ec2_sg) > 0 ? aws_security_group.ec2_sg[0].id : data.aws_security_group.existing_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "my-simple-app"
  }
}

# -------------------------
# Outputs
# -------------------------
output "ec2_public_ip" {
  value = aws_instance.app.public_ip
}

output "private_key_pem" {
  value     = length(aws_key_pair.deployer) > 0 ? tls_private_key.new_key[0].private_key_pem : "Use existing key pair"
  sensitive = true
}

output "ecr_repository_uri" {
  value = length(aws_ecr_repository.app_repo) > 0 ? aws_ecr_repository.app_repo[0].repository_url : var.ecr_repo_name
}
