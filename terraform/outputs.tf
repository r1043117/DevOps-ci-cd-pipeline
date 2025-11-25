# OUTPUTS - These display useful information after Terraform creates your resources
# Think of them like "return values" that show you what was created

output "app_server_id" {
  description = "The ID of the EC2 instance (unique identifier in AWS)"
  value       = aws_instance.app_server.id
}

output "app_server_public_ip" {
  description = "The public IP address to connect to your App Server"
  value       = aws_instance.app_server.public_ip
}

output "app_server_private_ip" {
  description = "The private IP address within AWS (internal use)"
  value       = aws_instance.app_server.private_ip
}

output "ssh_connection_command" {
  description = "Copy and paste this command to SSH into your App Server"
  value       = "ssh -i ~/.ssh/klinkr-key.pem admin@${aws_instance.app_server.public_ip}"
}

output "flask_app_url" {
  description = "URL to access the Flask application (once deployed)"
  value       = "http://${aws_instance.app_server.public_ip}:5000"
}

output "debian_ami_used" {
  description = "The Debian 12 image ID that was used"
  value       = data.aws_ami.debian12.id
}
