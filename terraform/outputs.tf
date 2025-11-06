# -------------------------
# Corrected Outputs
# -------------------------

# Default VPC
output "vpc_id" {
  description = "ID of the default VPC"
  value       = data.aws_vpc.default.id
}

# One of the default subnets
output "public_subnet_id" {
  description = "ID of the first default subnet"
  value       = element(data.aws_subnets.default.ids, 0)
}

# App security group (created or existing)
output "security_group_id" {
  description = "Security group ID used for the EC2 instance"
  value = try(
    aws_security_group.app_sg[0].id,
    data.aws_security_group.existing_sg.id
  )
}

# ECR repository URL (created or existing)
output "ecr_repository_uri" {
  description = "ECR repository URI (created or reused)"
  value = try(
    aws_ecr_repository.app_repo[0].repository_url,
    data.aws_ecr_repository.existing.repository_url
  )
}

# EC2 public IP address
output "ec2_public_ip" {
  value = var.ec2_public_ip
}

# Private key (only output if a new key pair was created)
output "private_key_pem" {
  description = "Private key PEM (only if Terraform created a new key pair)"
  value       = length(aws_key_pair.deployer) > 0 ? tls_private_key.ec2_key[0].private_key_pem : "Using existing key pair"
  sensitive   = true
}
