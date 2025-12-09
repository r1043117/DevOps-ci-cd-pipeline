
# TERRAFORM MAIN CONFIGURATIE

# Dit bestand bevat de hoofdconfiguratie voor onze infrastructuur.
# We maken hier:
#   - 2 EC2 instances (virtuele servers)
#   - 2 Security Groups (firewall regels)
#   - 2 Elastic IPs (vaste publieke IP adressen)




# VARIABELEN

# Variabelen zijn als "instellingen" die je kunt aanpassen.
# Dit maakt je code herbruikbaar - je hoeft niet overal
# handmatig waardes te veranderen.


variable "aws_region" {
  description = "De AWS regio waar we de servers aanmaken"
  type        = string
  default     = "eu-west-1"  # Ierland - dichtbij voor lage latency
}

variable "ssh_key_name" {
  description = "De naam van je SSH key pair in AWS"
  type        = string
  default     = "klinkr-key"  # Onze key naam
}



# DATA SOURCE - Debian 12 AMI opzoeken

# Een AMI (Amazon Machine Image) is een "sjabloon" voor je server.
# In plaats van handmatig de AMI-ID op te zoeken, laten we
# Terraform automatisch de nieuwste Debian 12 image vinden.


data "aws_ami" "debian12" {
  most_recent = true  # Neemt de nieuwste versie
  owners      = ["136693071363"]  # Officieel Debian AWS account

  # Filter om precies Debian 12 te vinden
  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]  # * betekent wildcard dat nul of meer willekeurige tekens heeft. (matched timestamp of build nummer)
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]  # Hardware Virtual Machine (moderne virtualisatie)
  }
}



# SECURITY GROUP - APP SERVER

# Een Security Group is als een firewall voor je server.
# Hier bepalen we welk netwerkverkeer is toegestaan.


resource "aws_security_group" "app_server_sg" {
  name        = "app-server-sg"
  description = "Firewall regels voor de App Server (Flask applicatie)"

  # --- INKOMEND VERKEER (van internet naar server) ---

  # SSH toegang (poort 22) - om in te loggen op de server
  ingress {
    description = "SSH toegang"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Vanaf elk IP adres
  }

  # HTTP verkeer (poort 80) - voor de website
  ingress {
    description = "HTTP webverkeer"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS verkeer (poort 443) - voor beveiligde website
  ingress {
    description = "HTTPS webverkeer"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Flask development poort (5000)
  ingress {
    description = "Flask development poort"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Staging omgeving poort (8080)
  # Hiermee kan de staging container bereikt worden voor testen
  # voordat we naar productie deployen
  ingress {
    description = "Staging omgeving"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # --- UITGAAND VERKEER (van server naar internet) ---
  # We staan alles toe zodat de server updates kan downloaden, etc.
  egress {
    description = "Alle uitgaand verkeer toestaan"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # -1 betekent alle protocollen
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "app-server-sg"
    Environment = "lab"
    ManagedBy   = "terraform"
  }
}



# SECURITY GROUP - JENKINS SERVER

resource "aws_security_group" "jenkins_server_sg" {
  name        = "jenkins-server-sg"
  description = "Firewall regels voor de Jenkins CI/CD Server"

  # SSH toegang
  ingress {
    description = "SSH toegang"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins web interface (poort 8080)
  ingress {
    description = "Jenkins web interface"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Uitgaand verkeer
  egress {
    description = "Alle uitgaand verkeer toestaan"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "jenkins-server-sg"
    Environment = "lab"
    ManagedBy   = "terraform"
  }
}



# EC2 INSTANCE - APP SERVER

# Dit is de virtuele machine waar onze Flask app draait.
# We gebruiken t3.micro (free tier - 2 vCPUs, 1GB RAM)


resource "aws_instance" "app_server" {
  ami           = data.aws_ami.debian12.id  # Debian 12 image.(ami = Amazon Machine Image)
  instance_type = "t3.micro"                 # Free tier

  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.app_server_sg.id]

  # Schijfruimte configuratie
  root_block_device {
    volume_size = 20    # 20 GB 
    volume_type = "gp3" # Snelle SSD
  }

  tags = {
    Name        = "app-server"
    Environment = "lab"
    Purpose     = "flask-app-server"
    ManagedBy   = "terraform"
    OS          = "debian-12"
  }
}



# EC2 INSTANCE - JENKINS SERVER

# Dit is de virtuele machine waar Jenkins draait.
# Jenkins zal automatisch bouwen wanneer we code pushen.


resource "aws_instance" "jenkins_server" {
  ami           = data.aws_ami.debian12.id
  instance_type = "t3.micro"

  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.jenkins_server_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name        = "jenkins-server"
    Environment = "lab"
    Purpose     = "ci-cd-server"
    ManagedBy   = "terraform"
    OS          = "debian-12"
  }
}



# ELASTIC IPs

# Een Elastic IP is een vast publiek IP adres.
# Normaal krijgt een EC2 instance een nieuw IP bij elke herstart.
# Met een Elastic IP blijft het IP adres altijd hetzelfde.
#
# GRATIS zolang de instance draait (Wordt mee gedestroyed via terraform destroy cmd)



resource "aws_eip" "app_server" {
  instance = aws_instance.app_server.id
  domain   = "vpc"

  tags = {
    Name        = "app-server-eip"
    Environment = "lab"
    ManagedBy   = "terraform"
  }
}

resource "aws_eip" "jenkins_server" {
  instance = aws_instance.jenkins_server.id
  domain   = "vpc"

  tags = {
    Name        = "jenkins-server-eip"
    Environment = "lab"
    ManagedBy   = "terraform"
  }
}
