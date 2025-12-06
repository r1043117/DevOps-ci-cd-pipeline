
# TERRAFORM OUTPUTS

# Outputs tonen nuttige informatie na 'terraform apply'.
# Dit zijn de IP adressen en URLs die je nodig hebt om
# verbinding te maken met je servers.


# --- APP SERVER INFO ---

output "app_server_public_ip" {
  description = "Publiek IP adres van de App Server"
  value       = aws_eip.app_server.public_ip
}

output "app_server_private_ip" {
  description = "Privé IP adres van de App Server"
  value       = aws_instance.app_server.private_ip
}

output "flask_app_url" {
  description = "URL om de Flask applicatie te bekijken"
  value       = "http://${aws_eip.app_server.public_ip}"
}

output "ssh_connection_command" {
  description = "Commando om via SSH te verbinden met App Server"
  value       = "ssh -i ~/.ssh/${var.ssh_key_name}.pem admin@${aws_eip.app_server.public_ip}"
}


# --- JENKINS SERVER INFO ---

output "jenkins_server_public_ip" {
  description = "Publiek IP adres van de Jenkins Server"
  value       = aws_eip.jenkins_server.public_ip
}

output "jenkins_url" {
  description = "URL voor de Jenkins web interface"
  value       = "http://${aws_eip.jenkins_server.public_ip}:8080"
}

output "jenkins_ssh_command" {
  description = "Commando om via SSH te verbinden met Jenkins Server"
  value       = "ssh -i ~/.ssh/${var.ssh_key_name}.pem admin@${aws_eip.jenkins_server.public_ip}"
}


# --- DNS INFO ---

output "app_domain_url" {
  description = "Flask app via domeinnaam"
  value       = "http://app.${var.domain_name}"
}

output "jenkins_domain_url" {
  description = "Jenkins via domeinnaam"
  value       = "http://jenkins.${var.domain_name}:8080"
}


# --- EXTRA INFO ---

output "debian_ami_used" {
  description = "De Debian 12 AMI die is gebruikt"
  value       = data.aws_ami.debian12.id
}

output "dns_note" {
  description = "DNS propagatie notitie"
  value       = "DNS records zijn aangemaakt. Propagatie kan 5-30 minuten duren."
}
