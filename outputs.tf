output "vpc_id" {
  description = "ID of the Jenkins VPC."
  value       = aws_vpc.jenkins.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = [for s in aws_subnet.private : s.id]
}

output "jenkins_security_group_id" {
  description = "Security group protecting the Jenkins instance."
  value       = aws_security_group.jenkins.id
}

output "jenkins_instance_id" {
  description = "Jenkins EC2 instance ID."
  value       = aws_instance.jenkins.id
}

output "jenkins_private_ip" {
  description = "Private IP of the Jenkins EC2 instance."
  value       = aws_instance.jenkins.private_ip
}

