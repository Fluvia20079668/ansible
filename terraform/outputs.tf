output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.web_server.public_dns
}

output "ecr_repository_uri" {
  description = "URI of the existing ECR repository"
  value       = data.aws_ecr_repository.app.repository_url
}
