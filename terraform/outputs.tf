# OUTPUTS - These display useful information after Terraform creates your resources
# Think of them like "return values" that show you what was created

output "app_server_id" {
  description = "The ID of the EC2 instance (unique identifier in AWS)"
  value       = aws_instance.app_server.id
}

output "app_server_public_ip" {
  description = "The Elastic IP address to connect to your App Server (static)"
  value       = aws_eip.app_server.public_ip
}

output "app_server_private_ip" {
  description = "The private IP address within AWS (internal use)"
  value       = aws_instance.app_server.private_ip
}

output "ssh_connection_command" {
  description = "Copy and paste this command to SSH into your App Server"
  value       = "ssh -i ~/.ssh/klinkr-key.pem admin@${aws_eip.app_server.public_ip}"
}

output "flask_app_url" {
  description = "URL to access the Flask application (once deployed)"
  value       = "http://${aws_eip.app_server.public_ip}:5000"
}

output "debian_ami_used" {
  description = "The Debian 12 image ID that was used"
  value       = data.aws_ami.debian12.id
}

# ============================================================
# VM2 - JENKINS SERVER OUTPUTS
# ============================================================

output "jenkins_server_id" {
  description = "The ID of the Jenkins EC2 instance"
  value       = aws_instance.jenkins_server.id
}

output "jenkins_server_public_ip" {
  description = "The Elastic IP address of the Jenkins server (static)"
  value       = aws_eip.jenkins_server.public_ip
}

output "jenkins_server_private_ip" {
  description = "The private IP address of the Jenkins server"
  value       = aws_instance.jenkins_server.private_ip
}

output "jenkins_ssh_command" {
  description = "SSH command to connect to Jenkins server"
  value       = "ssh -i ~/.ssh/klinkr-key.pem admin@${aws_eip.jenkins_server.public_ip}"
}

output "jenkins_url" {
  description = "URL to access Jenkins web interface (after installation)"
  value       = "http://${aws_eip.jenkins_server.public_ip}:8080"
}
