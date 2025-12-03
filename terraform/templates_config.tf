
# TERRAFORM TEMPLATE CONFIGURATIE
# Dit bestand genereert automatisch de Jenkinsfile en inventory.ini
# met de juiste IP adressen na 'terraform apply'.


# Genereer Jenkinsfile met de App Server IP
resource "local_file" "jenkinsfile" {
  content = templatefile("${path.module}/templates/Jenkinsfile.tpl", {
    app_server_ip = aws_eip.app_server.public_ip
    ssh_user      = "admin"
  })

  filename = "${path.module}/../Jenkinsfile"
}


# Genereer Ansible inventory met beide server IPs
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.ini.tpl", {
    app_server_ip     = aws_eip.app_server.public_ip
    jenkins_server_ip = aws_eip.jenkins_server.public_ip
    ssh_user          = "admin"
    ssh_key_name      = var.ssh_key_name
  })

  filename = "${path.module}/../ansible/inventory.ini"
}
