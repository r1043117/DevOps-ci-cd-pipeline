
# DNS CONFIGURATIE - GANDI
# Dit bestand beheert de DNS records voor klinkr.be
# A-records worden automatisch bijgewerkt met de Elastic IPs


# Variabele voor domeinnaam
variable "domain_name" {
  description = "Je domeinnaam bij Gandi"
  type        = string
  default     = "klinkr.be"
}


# A-record voor app.klinkr.be -> App Server
resource "gandi_livedns_record" "app" {
  zone   = var.domain_name
  name   = "app"
  type   = "A"
  ttl    = 300  # 5 minuten - laag voor snelle updates
  values = [aws_eip.app_server.public_ip]
}


# A-record voor jenkins.klinkr.be -> Jenkins Server
resource "gandi_livedns_record" "jenkins" {
  zone   = var.domain_name
  name   = "jenkins"
  type   = "A"
  ttl    = 300
  values = [aws_eip.jenkins_server.public_ip]
}
