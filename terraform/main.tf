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

# -------------------------
# Provider Configuration
# -------------------------
provider "aws" {
  region = var.aws_region
}

# -------------------------
# ECR Repository (create if missing)
# -------------------------
data "aws_ecr_repository" "existing" {
  name = var.ecr_repo_name
}

resource "aws_ecr_repository" "app_repo" {
  count = try(data.aws_ecr_repository.existing.id, "") == "" ? 1 : 0
  name  = var.ecr_repo_name

  tags = {
    Name = "${var.project_name}-ecr"
  }
}

# -------------------------
# EC2 Key Pair (create if missing)
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
# Security Group (reuse if exists)
# -------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_security_group" "existing_sg" {
  filter {
    name   = "group-name"
    values = ["app-sg"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "app_sg" {
  count       = try(data.aws_security_group.existing_sg.id, "") == "" ? 1 : 0
  name        = "app-sg"
  description = "Allow SSH and application traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App Port (8090)"
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
    Name = "${var.project_name}-sg"
  }
}

# -------------------------
# Subnet & AMI
# -------------------------
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# -------------------------
# EC2 Instance
# -------------------------
resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = element(data.aws_subnets.default.ids, 0)
  associate_public_ip_address = true
  key_name                    = length(aws_key_pair.deployer) > 0 ? aws_key_pair.deployer[0].key_name : var.key_pair_name
  vpc_security_group_ids      = [length(aws_security_group.app_sg) > 0 ? aws_security_group.app_sg[0].id : data.aws_security_group.existing_sg.id]

  tags = {
    Name = "${var.project_name}-ec2"
  }
}

# -------------------------
# Outputs
# -------------------------
output "ec2_public_ip" {
  value = aws_instance.app_server.public_ip
}

output "ecr_repository_uri" {
  value = try(
    aws_ecr_repository.app_repo[0].repository_url,
    data.aws_ecr_repository.existing.repository_url
  )
}

output "private_key_pem" {
  value     = length(aws_key_pair.deployer) > 0 ? tls_private_key.ec2_key[0].private_key_pem : "Using existing key pair"
  sensitive = true
}
