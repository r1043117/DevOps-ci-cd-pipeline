# CI/CD Pipeline met AWS, Terraform, Ansible en Jenkins

Een complete handleiding voor het opzetten van een geautomatiseerde deployment pipeline.

In deze handleiding leer je stap voor stap hoe je een professionele CI/CD (Continuous Integration / Continuous Deployment) omgeving opzet. We gebruiken populaire DevOps tools die ook in het bedrijfsleven worden gebruikt.


## Wat gaan we bouwen?

We maken twee servers in de Amazon cloud:

1. Een App Server waar onze Flask webapplicatie draait in een Docker container
2. Een Jenkins Server die automatisch nieuwe versies van onze app deployt wanneer we code pushen naar GitHub

De infrastructuur wordt volledig geautomatiseerd aangemaakt met Terraform, en de servers worden geconfigureerd met Ansible.

[Screenshot: Architectuur overzicht - twee servers met pijlen tussen GitHub, Jenkins en App Server]


## Wat heb je nodig?

Voordat we beginnen, moeten we een aantal tools installeren op je computer. We werken in WSL (Windows Subsystem for Linux) met Debian.

### Tools installeren

Open een terminal in WSL en voer de volgende commando's uit:

```bash
# Systeem updaten
sudo apt update && sudo apt upgrade -y

# Python en pip installeren
sudo apt install python3 python3-pip -y

# Ansible installeren
pip3 install ansible

# AWS CLI installeren
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Terraform installeren
sudo apt install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y

# Git installeren (als je dat nog niet hebt)
sudo apt install git -y
```

### Controleren of alles werkt

Test of alle tools correct zijn geinstalleerd:

```bash
# Versies controleren
python3 --version
ansible --version
aws --version
terraform --version
git --version
```

Je zou voor elk commando een versienummer moeten zien. Als een commando niet werkt, installeer die tool dan opnieuw.

[Screenshot: Terminal met versie outputs van alle tools]


## AWS Account Opzetten

Om servers in de cloud te kunnen maken, heb je een AWS account nodig.

### Account aanmaken

1. Ga naar https://aws.amazon.com en klik op "Create an AWS Account"
2. Vul je emailadres en een accountnaam in
3. Kies een wachtwoord
4. Vul je contactgegevens in
5. Voer betaalgegevens in (je krijgt 12 maanden gratis tier, t3.micro instances zijn gratis)
6. Bevestig je identiteit via SMS
7. Kies het "Basic Support" plan (gratis)

[Screenshot: AWS account aanmaak pagina]

### IAM User aanmaken

We gaan een speciale gebruiker aanmaken voor Terraform. Dit is veiliger dan je root account gebruiken.

1. Log in op de AWS Console
2. Zoek naar "IAM" in de zoekbalk en open de IAM service
3. Klik links op "Users" en dan "Create user"
4. Geef de gebruiker een naam, bijvoorbeeld "terraform-user"
5. Klik op "Next"
6. Kies "Attach policies directly"
7. Zoek en selecteer "AdministratorAccess"
8. Klik op "Next" en dan "Create user"

[Screenshot: IAM user aanmaken]

### Access Keys genereren

1. Klik op de nieuwe gebruiker in de lijst
2. Ga naar het tabblad "Security credentials"
3. Scroll naar "Access keys" en klik "Create access key"
4. Kies "Command Line Interface (CLI)"
5. Bevestig en klik "Create access key"
6. BELANGRIJK: Kopieer de Access Key ID en Secret Access Key. Je ziet de secret key maar een keer!

[Screenshot: Access keys pagina]

### AWS CLI configureren

Nu gaan we de AWS CLI configureren met je nieuwe credentials:

```bash
aws configure
```

Vul de volgende gegevens in:
- AWS Access Key ID: (plak je access key)
- AWS Secret Access Key: (plak je secret key)
- Default region name: eu-west-1
- Default output format: json

Test of de configuratie werkt:

```bash
aws sts get-caller-identity
```

Je zou je account ID en gebruikersnaam moeten zien.

[Screenshot: AWS configure en test output]


## SSH Key Pair Aanmaken

Om in te kunnen loggen op onze servers, hebben we een SSH sleutel nodig.

### Key pair maken in AWS

1. Ga naar de AWS Console
2. Zorg dat je in regio "eu-west-1" (Ireland) zit (rechtsboven in de console)
3. Zoek naar "EC2" en open de EC2 service
4. Klik links onder "Network & Security" op "Key Pairs"
5. Klik "Create key pair"
6. Naam: klinkr-key (of een andere naam, maar onthoud deze!)
7. Type: RSA
8. Format: .pem
9. Klik "Create key pair"

Het .pem bestand wordt automatisch gedownload.

[Screenshot: Key pair aanmaken]

### Key verplaatsen naar WSL

Het gedownloade bestand staat waarschijnlijk in je Windows Downloads map. We moeten het naar WSL verplaatsen:

```bash
# Maak .ssh map aan als die niet bestaat
mkdir -p ~/.ssh

# Kopieer de key (pas het pad aan naar waar jouw key staat)
cp /mnt/c/Users/JOUW_GEBRUIKERSNAAM/Downloads/klinkr-key.pem ~/.ssh/

# Zet de juiste permissies (heel belangrijk!)
chmod 600 ~/.ssh/klinkr-key.pem

# Controleer of de key er staat
ls -la ~/.ssh/
```

Je zou nu het bestand "klinkr-key.pem" moeten zien met permissies "-rw-------".

[Screenshot: SSH key in .ssh map]


## Project Structuur Aanmaken

Nu gaan we de mappenstructuur voor ons project opzetten.

### Hoofdmap aanmaken

```bash
# Ga naar je home directory
cd ~

# Maak de project map
mkdir cicd-aws-terraform
cd cicd-aws-terraform

# Maak de submappen
mkdir -p terraform/templates
mkdir -p ansible/playbooks
mkdir -p ansible/group_vars/all
mkdir -p flask-app/templates
mkdir -p flask-app/static/css
```

### Controleren

```bash
# Bekijk de structuur
find . -type d
```

Je zou deze structuur moeten zien:
```
.
./terraform
./terraform/templates
./ansible
./ansible/playbooks
./ansible/group_vars
./ansible/group_vars/all
./flask-app
./flask-app/templates
./flask-app/static
./flask-app/static/css
```

[Screenshot: Project structuur]

### Gitignore aanmaken

Maak een .gitignore bestand aan zodat gevoelige bestanden niet per ongeluk naar GitHub worden gepusht:

```bash
cat > .gitignore << 'EOF'
# Terraform
terraform/.terraform/
terraform/*.tfstate
terraform/*.tfstate.*
terraform/*.tfvars
terraform/.terraform.lock.hcl

# Ansible
ansible/inventory.ini
ansible/*.retry
ansible/group_vars/all/vault.yml
ansible/.vault_pass.txt

# Generated files
Jenkinsfile

# OS files
.DS_Store
*.swp
*.swo

# IDE
.vscode/
.idea/

# Python
__pycache__/
*.pyc
*.pyo
EOF
```


## Terraform Configuratie

Terraform is een tool waarmee je infrastructuur als code kunt schrijven. In plaats van handmatig servers aanmaken via de AWS console, beschrijven we wat we nodig hebben in configuratiebestanden.

### Provider configureren

De provider vertelt Terraform welke cloud we gebruiken. Maak het bestand terraform/provider.tf aan:

```bash
cat > terraform/provider.tf << 'EOF'
# TERRAFORM PROVIDER CONFIGURATIE
# Dit bestand vertelt Terraform welke cloud provider we gebruiken.
# In ons geval is dat Amazon Web Services (AWS).

# Hier geven we aan welke provider plugin Terraform moet downloaden.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Hier configureren we de verbinding met AWS.
# Terraform gebruikt automatisch de credentials van 'aws configure'
provider "aws" {
  region = var.aws_region
}
EOF
```

### Hoofdconfiguratie aanmaken

Dit is het belangrijkste bestand. Hier definiëren we onze servers en netwerkinstellingen. Maak terraform/main.tf aan:

```bash
cat > terraform/main.tf << 'EOF'
# TERRAFORM MAIN CONFIGURATIE
# We maken hier:
#   - 2 EC2 instances (virtuele servers)
#   - 2 Security Groups (firewall regels)
#   - 2 Elastic IPs (vaste publieke IP adressen)


# VARIABELEN

variable "aws_region" {
  description = "De AWS regio waar we de servers aanmaken"
  type        = string
  default     = "eu-west-1"
}

variable "ssh_key_name" {
  description = "De naam van je SSH key pair in AWS"
  type        = string
  default     = "klinkr-key"
}


# DATA SOURCE - Debian 12 AMI opzoeken
# Een AMI is een template voor je server. We zoeken automatisch de nieuwste Debian 12.

data "aws_ami" "debian12" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# SECURITY GROUP - APP SERVER
# Een Security Group is een firewall voor je server.

resource "aws_security_group" "app_server_sg" {
  name        = "app-server-sg"
  description = "Firewall regels voor de App Server"

  # SSH toegang (poort 22)
  ingress {
    description = "SSH toegang"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP verkeer (poort 80)
  ingress {
    description = "HTTP webverkeer"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS verkeer (poort 443)
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

  # Uitgaand verkeer
  egress {
    description = "Alle uitgaand verkeer toestaan"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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
  description = "Firewall regels voor de Jenkins Server"

  ingress {
    description = "SSH toegang"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins web interface"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.debian12.id
  instance_type = "t3.micro"

  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.app_server_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
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
EOF
```

### Outputs configureren

Outputs tonen nuttige informatie na het deployen. Maak terraform/outputs.tf aan:

```bash
cat > terraform/outputs.tf << 'EOF'
# TERRAFORM OUTPUTS
# Deze informatie zie je na 'terraform apply'

output "app_server_public_ip" {
  description = "Publiek IP adres van de App Server"
  value       = aws_eip.app_server.public_ip
}

output "flask_app_url" {
  description = "URL om de Flask applicatie te bekijken"
  value       = "http://${aws_eip.app_server.public_ip}"
}

output "ssh_connection_command" {
  description = "Commando om via SSH te verbinden met App Server"
  value       = "ssh -i ~/.ssh/${var.ssh_key_name}.pem admin@${aws_eip.app_server.public_ip}"
}

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

output "debian_ami_used" {
  description = "De Debian 12 AMI die is gebruikt"
  value       = data.aws_ami.debian12.id
}
EOF
```

### Templates voor automatisch gegenereerde bestanden

Terraform kan automatisch bestanden genereren met de juiste IP adressen. Maak terraform/templates_config.tf aan:

```bash
cat > terraform/templates_config.tf << 'EOF'
# TERRAFORM TEMPLATE CONFIGURATIE
# Dit genereert automatisch de Jenkinsfile en inventory.ini

resource "local_file" "jenkinsfile" {
  content = templatefile("${path.module}/templates/Jenkinsfile.tpl", {
    app_server_ip = aws_eip.app_server.public_ip
    ssh_user      = "admin"
  })

  filename = "${path.module}/../Jenkinsfile"
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.ini.tpl", {
    app_server_ip     = aws_eip.app_server.public_ip
    jenkins_server_ip = aws_eip.jenkins_server.public_ip
    ssh_user          = "admin"
    ssh_key_name      = var.ssh_key_name
  })

  filename = "${path.module}/../ansible/inventory.ini"
}
EOF
```

### Inventory template

Maak terraform/templates/inventory.ini.tpl aan:

```bash
cat > terraform/templates/inventory.ini.tpl << 'EOF'
# ANSIBLE INVENTORY (AUTO-GENERATED)
# Dit bestand is automatisch gegenereerd door Terraform.

[app_servers]
vm1 ansible_host=${app_server_ip} ansible_user=${ssh_user} ansible_ssh_private_key_file=~/.ssh/${ssh_key_name}.pem

[jenkins_servers]
vm2 ansible_host=${jenkins_server_ip} ansible_user=${ssh_user} ansible_ssh_private_key_file=~/.ssh/${ssh_key_name}.pem

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
```

### Jenkinsfile template

Maak terraform/templates/Jenkinsfile.tpl aan:

```bash
cat > terraform/templates/Jenkinsfile.tpl << 'EOF'
// JENKINSFILE (AUTO-GENERATED BY TERRAFORM)

pipeline {
    agent any

    environment {
        APP_SERVER = '${app_server_ip}'
        APP_USER = '${ssh_user}'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Code ophalen van GitHub...'
                checkout scm
            }
        }

        stage('Pull Latest Code') {
            steps {
                echo "Laatste code ophalen op $${APP_SERVER}..."
                sshagent(['vm1-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no $${APP_USER}@$${APP_SERVER} '
                            cd /opt/flask-app &&
                            git pull origin main
                        '
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Docker image bouwen op $${APP_SERVER}..."
                sshagent(['vm1-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no $${APP_USER}@$${APP_SERVER} '
                            cd /opt/flask-app/flask-app &&
                            sudo docker build -t flask-app:latest . &&
                            sudo docker stop flask-app || true &&
                            sudo docker rm flask-app || true &&
                            sudo docker run -d --name flask-app --restart unless-stopped -p 80:80 flask-app:latest
                        '
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                echo 'Wachten tot container is opgestart...'
                sh 'sleep 10'
                echo 'Controleren of app draait...'
                sh "curl -f http://$${APP_SERVER}:80/health || exit 1"
            }
        }
    }

    post {
        success {
            echo 'Deployment geslaagd!'
            echo "App URL: http://$${APP_SERVER}"
        }
        failure {
            echo 'Deployment mislukt!'
        }
    }
}
EOF
```

### Terraform initialiseren en testen

Nu gaan we controleren of onze Terraform configuratie correct is:

```bash
cd ~/cicd-aws-terraform/terraform

# Terraform initialiseren (download providers)
terraform init

# Configuratie valideren
terraform validate

# Plan bekijken (laat zien wat er gemaakt gaat worden)
terraform plan
```

Je zou moeten zien dat Terraform 6 resources gaat aanmaken (2 instances, 2 security groups, 2 elastic IPs, plus 2 lokale bestanden).

[Screenshot: Terraform plan output]

### Infrastructuur aanmaken

Als het plan er goed uitziet, maken we de infrastructuur aan:

```bash
terraform apply
```

Type "yes" wanneer gevraagd. Dit duurt ongeveer 2-3 minuten. Na afloop zie je de outputs met IP adressen.

BELANGRIJK: Noteer de IP adressen! Je hebt ze nodig voor de volgende stappen.

[Screenshot: Terraform apply output met IP adressen]

### Testen of servers bereikbaar zijn

```bash
# Test SSH naar App Server (vervang IP_ADRES)
ssh -i ~/.ssh/klinkr-key.pem admin@IP_ADRES_APP_SERVER

# Als je succesvol inlogt, type 'exit' om terug te gaan

# Test SSH naar Jenkins Server
ssh -i ~/.ssh/klinkr-key.pem admin@IP_ADRES_JENKINS_SERVER
```


## Ansible Configuratie

Ansible is een tool om servers te configureren. In plaats van handmatig software installeren, schrijven we playbooks die automatisch uitgevoerd worden.

### Ansible config bestand

Maak ansible/ansible.cfg aan:

```bash
cat > ansible/ansible.cfg << 'EOF'
# ANSIBLE CONFIGURATIE

[defaults]
inventory = inventory.ini
remote_user = admin
host_key_checking = False
vault_password_file = .vault_pass.txt
timeout = 30
forks = 5
force_color = True
deprecation_warnings = False

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
EOF
```

### Gedeelde variabelen

Maak ansible/group_vars/all/vars.yml aan:

```bash
cat > ansible/group_vars/all/vars.yml << 'EOF'
# GEDEELDE VARIABELEN
# Deze variabelen zijn beschikbaar in ALLE playbooks.

# --- FLASK APPLICATIE ---
flask_app_name: "flask-app"
flask_app_port: 80
flask_app_repo: "https://github.com/JOUW_GITHUB_USERNAME/cicd-aws-terraform.git"
flask_app_branch: "main"
flask_app_path: "/opt/flask-app"

# --- DOCKER ---
docker_compose_version: "2.24.0"

# --- JENKINS ---
jenkins_http_port: 8080
jenkins_admin_user: "admin"
# Het Jenkins wachtwoord staat in vault.yml (versleuteld)

# --- SSH ---
ssh_key_name: "klinkr-key"
EOF
```

Let op: Vervang JOUW_GITHUB_USERNAME met je eigen GitHub gebruikersnaam!

### Ansible Vault instellen

We gaan gevoelige informatie zoals wachtwoorden versleutelen met Ansible Vault.

Maak eerst een voorbeeld bestand:

```bash
cat > ansible/group_vars/all/vault.yml.example << 'EOF'
# ANSIBLE VAULT VOORBEELD
# Kopieer naar 'vault.yml' en vul je eigen wachtwoord in
# Versleutel met: ansible-vault encrypt vault.yml

vault_jenkins_admin_pass: "KIES_EEN_STERK_WACHTWOORD"
EOF
```

Maak nu de echte vault.yml:

```bash
# Kopieer het voorbeeld
cp ansible/group_vars/all/vault.yml.example ansible/group_vars/all/vault.yml

# Bewerk het bestand en kies een wachtwoord
nano ansible/group_vars/all/vault.yml
```

Verander "KIES_EEN_STERK_WACHTWOORD" naar een echt wachtwoord dat je wilt gebruiken voor Jenkins.

Maak nu een bestand met het vault wachtwoord:

```bash
# Maak .vault_pass.txt aan met een wachtwoord om de vault te ontgrendelen
echo "MijnVaultWachtwoord123" > ansible/.vault_pass.txt

# Beveilig het bestand
chmod 600 ansible/.vault_pass.txt
```

Versleutel de vault:

```bash
cd ~/cicd-aws-terraform/ansible
ansible-vault encrypt group_vars/all/vault.yml
```

Je kunt de inhoud bekijken met:

```bash
ansible-vault view group_vars/all/vault.yml
```

[Screenshot: Ansible vault encrypt en view]


### Docker playbook

Dit playbook installeert Docker. Maak ansible/playbooks/docker.yml aan:

```bash
cat > ansible/playbooks/docker.yml << 'EOF'
---
# DOCKER INSTALLATIE PLAYBOOK

- name: Install Docker on all servers
  hosts: all
  become: true

  tasks:
    - name: Install required packages
      apt:
        name:
          - apt-transport-https
          - ca-certificates
          - curl
          - gnupg
          - lsb-release
          - python3-pip
        state: present
        update_cache: yes

    - name: Add Docker GPG key
      apt_key:
        url: https://download.docker.com/linux/debian/gpg
        state: present

    - name: Add Docker repository
      apt_repository:
        repo: "deb [arch=amd64] https://download.docker.com/linux/debian {{ ansible_distribution_release }} stable"
        state: present

    - name: Install Docker
      apt:
        name:
          - docker-ce
          - docker-ce-cli
          - containerd.io
        state: present
        update_cache: yes

    - name: Install Docker Python module
      pip:
        name: docker
        state: present

    - name: Add admin user to docker group
      user:
        name: admin
        groups: docker
        append: yes

    - name: Start and enable Docker service
      systemd:
        name: docker
        state: started
        enabled: yes

    - name: Verify Docker is running
      command: docker --version
      register: docker_version
      changed_when: false

    - name: Show Docker version
      debug:
        msg: "Docker installed: {{ docker_version.stdout }}"
EOF
```

### Jenkins playbook

Dit is een uitgebreid playbook dat Jenkins installeert EN volledig configureert. Maak ansible/playbooks/jenkins.yml aan:

```bash
cat > ansible/playbooks/jenkins.yml << 'EOF'
---
# JENKINS INSTALLATIE EN CONFIGURATIE PLAYBOOK

- name: Install and Configure Jenkins
  hosts: jenkins_servers
  become: true

  vars:
    jenkins_admin_user: "{{ jenkins_admin_user }}"
    jenkins_admin_pass: "{{ vault_jenkins_admin_pass }}"
    jenkins_plugins:
      - git
      - workflow-aggregator
      - ssh-agent
      - credentials
      - credentials-binding

  tasks:
    # Java installeren (vereist voor Jenkins)
    - name: Install Java 17
      apt:
        name: openjdk-17-jdk
        state: present
        update_cache: yes

    # Jenkins repository toevoegen
    - name: Add Jenkins apt key
      apt_key:
        url: https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
        state: present

    - name: Add Jenkins repository
      apt_repository:
        repo: "deb https://pkg.jenkins.io/debian-stable binary/"
        state: present

    # Jenkins installeren
    - name: Install Jenkins
      apt:
        name: jenkins
        state: present
        update_cache: yes

    # Skip setup wizard
    - name: Create Jenkins init.groovy.d directory
      file:
        path: /var/lib/jenkins/init.groovy.d
        state: directory
        owner: jenkins
        group: jenkins
        mode: '0755'

    - name: Disable setup wizard
      lineinfile:
        path: /etc/default/jenkins
        regexp: '^JAVA_ARGS='
        line: 'JAVA_ARGS="-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"'
      notify: Restart Jenkins

    # Jenkins starten
    - name: Start Jenkins service
      systemd:
        name: jenkins
        state: started
        enabled: yes

    - name: Wait for Jenkins to start
      wait_for:
        port: 8080
        delay: 10
        timeout: 120

    # Jenkins CLI downloaden
    - name: Wait for Jenkins CLI
      uri:
        url: "http://localhost:8080/jnlpJars/jenkins-cli.jar"
        status_code: 200
      register: result
      until: result.status == 200
      retries: 30
      delay: 10

    - name: Download Jenkins CLI
      get_url:
        url: "http://localhost:8080/jnlpJars/jenkins-cli.jar"
        dest: /tmp/jenkins-cli.jar
        mode: '0755'

    # Initial admin password ophalen
    - name: Get initial admin password
      slurp:
        src: /var/lib/jenkins/secrets/initialAdminPassword
      register: admin_password_file
      ignore_errors: yes

    - name: Set initial password fact
      set_fact:
        jenkins_initial_password: "{{ admin_password_file.content | b64decode | trim }}"
      when: admin_password_file is succeeded

    # Plugins installeren
    - name: Install Jenkins plugins
      command: >
        java -jar /tmp/jenkins-cli.jar
        -s http://localhost:8080/
        -auth admin:{{ jenkins_initial_password }}
        install-plugin {{ item }}
      loop: "{{ jenkins_plugins }}"
      when: jenkins_initial_password is defined
      ignore_errors: yes

    - name: Restart Jenkins after plugin install
      systemd:
        name: jenkins
        state: restarted
      when: jenkins_initial_password is defined

    - name: Wait for Jenkins after restart
      wait_for:
        port: 8080
        delay: 10
        timeout: 120

    # Admin user aanmaken
    - name: Create admin user script
      copy:
        dest: /tmp/create-admin.groovy
        content: |
          import jenkins.model.*
          import hudson.security.*

          def instance = Jenkins.getInstance()
          def hudsonRealm = new HudsonPrivateSecurityRealm(false)
          hudsonRealm.createAccount("{{ jenkins_admin_user }}", "{{ jenkins_admin_pass }}")
          instance.setSecurityRealm(hudsonRealm)

          def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
          strategy.setAllowAnonymousRead(false)
          instance.setAuthorizationStrategy(strategy)
          instance.save()

          println "Admin user created successfully!"
        mode: '0644'

    - name: Create admin user via CLI
      command: >
        java -jar /tmp/jenkins-cli.jar
        -s http://localhost:8080/
        -auth admin:{{ jenkins_initial_password }}
        groovy = < /tmp/create-admin.groovy
      when: jenkins_initial_password is defined
      ignore_errors: yes

    # SSH key voor app server deployen
    - name: Copy SSH private key for deployments
      copy:
        src: "~/.ssh/{{ ssh_key_name }}.pem"
        dest: /var/lib/jenkins/.ssh/{{ ssh_key_name }}.pem
        owner: jenkins
        group: jenkins
        mode: '0600'

    # Output
    - name: Display Jenkins info
      debug:
        msg:
          - "Jenkins is installed and configured!"
          - "URL: http://{{ ansible_host }}:8080"
          - "Username: {{ jenkins_admin_user }}"
          - "Password: (your vault password)"

  handlers:
    - name: Restart Jenkins
      systemd:
        name: jenkins
        state: restarted
EOF
```

### Flask deployment playbook

Maak ansible/playbooks/deploy-flask.yml aan:

```bash
cat > ansible/playbooks/deploy-flask.yml << 'EOF'
---
# FLASK APPLICATIE DEPLOYMENT PLAYBOOK

- name: Deploy Flask Application
  hosts: app_servers
  become: true

  vars:
    app_name: "{{ flask_app_name }}"
    app_repo: "{{ flask_app_repo }}"
    app_branch: "{{ flask_app_branch }}"
    app_path: "{{ flask_app_path }}"

  tasks:
    - name: Install Git
      apt:
        name: git
        state: present
        update_cache: yes

    - name: Create application directory
      file:
        path: "{{ app_path }}"
        state: directory
        owner: admin
        group: admin
        mode: '0755'

    - name: Clone or update repository
      git:
        repo: "{{ app_repo }}"
        dest: "{{ app_path }}"
        version: "{{ app_branch }}"
        force: yes
      become_user: admin

    - name: Build Docker image
      community.docker.docker_image:
        name: "{{ app_name }}"
        tag: latest
        source: build
        build:
          path: "{{ app_path }}/flask-app"
        state: present
        force_source: yes

    - name: Stop existing container
      community.docker.docker_container:
        name: "{{ app_name }}"
        state: absent
      ignore_errors: yes

    - name: Start Flask container
      community.docker.docker_container:
        name: "{{ app_name }}"
        image: "{{ app_name }}:latest"
        state: started
        restart_policy: unless-stopped
        ports:
          - "80:80"

    - name: Wait for container to be healthy
      wait_for:
        port: 80
        delay: 5
        timeout: 60

    - name: Display deployment summary
      debug:
        msg:
          - "Flask Application Deployed!"
          - "Container: {{ app_name }}"
          - "URL: http://{{ ansible_host }}:80"
          - "Health: http://{{ ansible_host }}:80/health"
EOF
```

### Master playbook

Dit playbook voert alle andere playbooks uit. Maak ansible/playbooks/site.yml aan:

```bash
cat > ansible/playbooks/site.yml << 'EOF'
---
# MASTER PLAYBOOK
# Voert alle configuratie uit in de juiste volgorde

- import_playbook: docker.yml
- import_playbook: jenkins.yml
- import_playbook: deploy-flask.yml
EOF
```

### Ansible testen

Controleer of Ansible de servers kan bereiken:

```bash
cd ~/cicd-aws-terraform/ansible

# Ping alle servers
ansible all -m ping
```

Je zou "SUCCESS" moeten zien voor beide servers.

[Screenshot: Ansible ping output]


## Flask Applicatie

Nu maken we de webapplicatie die we gaan deployen.

### Python applicatie

Maak flask-app/app.py aan:

```bash
cat > flask-app/app.py << 'EOF'
# FLASK APPLICATIE
from flask import Flask, render_template, jsonify
import os
from datetime import datetime

app = Flask(__name__)


@app.route('/')
def home():
    return render_template('index.html',
                           hostname=os.uname().nodename,
                           timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


@app.route('/health')
def health():
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "hostname": os.uname().nodename
    })


@app.route('/api/info')
def api_info():
    return jsonify({
        "app": "Flask CI/CD Demo",
        "version": "1.0.0",
        "environment": os.getenv("ENVIRONMENT", "production"),
        "hostname": os.uname().nodename
    })


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80, debug=False)
EOF
```

### Requirements

Maak flask-app/requirements.txt aan:

```bash
cat > flask-app/requirements.txt << 'EOF'
flask==3.0.0
gunicorn==21.2.0
EOF
```

### Dockerfile

Maak flask-app/Dockerfile aan:

```bash
cat > flask-app/Dockerfile << 'EOF'
# DOCKERFILE VOOR FLASK APPLICATIE
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 80

CMD ["gunicorn", "--bind", "0.0.0.0:80", "app:app"]
EOF
```

### HTML Template

Maak flask-app/templates/index.html aan:

```bash
cat > flask-app/templates/index.html << 'EOF'
<!DOCTYPE html>
<html lang="nl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Flask CI/CD Demo</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
</head>
<body>
    <div class="container">
        <h1>Flask CI/CD Demo</h1>
        <div class="info-box">
            <p><strong>Hostname:</strong> {{ hostname }}</p>
            <p><strong>Timestamp:</strong> {{ timestamp }}</p>
        </div>
        <div class="links">
            <a href="/health">Health Check</a>
            <a href="/api/info">API Info</a>
        </div>
    </div>
</body>
</html>
EOF
```

### CSS Styling

Maak flask-app/static/css/style.css aan:

```bash
cat > flask-app/static/css/style.css << 'EOF'
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
    min-height: 100vh;
    display: flex;
    justify-content: center;
    align-items: center;
    color: #eee;
}

.container {
    background: rgba(255, 255, 255, 0.1);
    padding: 40px;
    border-radius: 20px;
    text-align: center;
    backdrop-filter: blur(10px);
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
}

h1 {
    margin-bottom: 30px;
    font-size: 2.5em;
    color: #4ecca3;
}

.info-box {
    background: rgba(0, 0, 0, 0.2);
    padding: 20px;
    border-radius: 10px;
    margin-bottom: 20px;
}

.info-box p {
    margin: 10px 0;
    font-size: 1.1em;
}

.links {
    margin-top: 20px;
}

.links a {
    display: inline-block;
    margin: 10px;
    padding: 12px 24px;
    background: #4ecca3;
    color: #1a1a2e;
    text-decoration: none;
    border-radius: 5px;
    font-weight: bold;
    transition: transform 0.2s, background 0.2s;
}

.links a:hover {
    transform: translateY(-2px);
    background: #3db892;
}
EOF
```


## Alles Deployen

Nu gaan we alles uitvoeren.

### Stap 1: Push naar GitHub

Eerst moet je project op GitHub staan:

```bash
cd ~/cicd-aws-terraform

# Git initialiseren
git init
git add .
git commit -m "Initial commit - CI/CD Pipeline project"

# Maak een repo aan op GitHub en push
git remote add origin https://github.com/JOUW_USERNAME/cicd-aws-terraform.git
git branch -M main
git push -u origin main
```

[Screenshot: GitHub repository]

### Stap 2: Ansible playbooks uitvoeren

```bash
cd ~/cicd-aws-terraform/ansible

# Voer alle playbooks uit
ansible-playbook playbooks/site.yml
```

Dit duurt ongeveer 5-10 minuten. Je ziet de voortgang in de terminal.

[Screenshot: Ansible playbook output]

### Stap 3: Controleren of alles werkt

Test de Flask applicatie:

```bash
# Vervang met je App Server IP
curl http://APP_SERVER_IP/health
```

Je zou een JSON response moeten zien met "status": "healthy".

Open in je browser:
- Flask app: http://APP_SERVER_IP
- Jenkins: http://JENKINS_SERVER_IP:8080

[Screenshot: Flask applicatie in browser]
[Screenshot: Jenkins login pagina]


## Jenkins Pipeline Configureren

Nu gaan we een Jenkins job aanmaken die automatisch deployt.

### Inloggen op Jenkins

1. Open http://JENKINS_SERVER_IP:8080
2. Log in met:
   - Username: admin
   - Password: (het wachtwoord dat je in vault.yml hebt gezet)

[Screenshot: Jenkins dashboard]

### SSH Credentials toevoegen

1. Ga naar "Manage Jenkins" > "Credentials"
2. Klik op "(global)" onder "Stores scoped to Jenkins"
3. Klik "Add Credentials"
4. Kind: SSH Username with private key
5. ID: vm1-ssh-key
6. Username: admin
7. Private Key: Enter directly, plak de inhoud van je .pem bestand
8. Klik "Create"

[Screenshot: SSH credentials toevoegen]

### Pipeline Job aanmaken

1. Klik "New Item" op het hoofdscherm
2. Naam: flask-pipeline
3. Type: Pipeline
4. Klik OK

In de configuratie:
1. Scroll naar "Pipeline"
2. Definition: Pipeline script from SCM
3. SCM: Git
4. Repository URL: https://github.com/JOUW_USERNAME/cicd-aws-terraform.git
5. Branch: */main
6. Script Path: Jenkinsfile
7. Klik "Save"

[Screenshot: Pipeline configuratie]

### Pipeline testen

1. Klik op de job "flask-pipeline"
2. Klik "Build Now"
3. Klik op de build om de console output te zien

[Screenshot: Succesvolle pipeline run]


## GitHub Webhook (Optioneel)

Je kunt een webhook instellen zodat Jenkins automatisch bouwt wanneer je code pusht.

### Jenkins configureren

1. Ga naar "Manage Jenkins" > "Configure System"
2. Scroll naar "GitHub" sectie
3. Voeg een GitHub server toe met API URL: https://api.github.com

### GitHub Webhook toevoegen

1. Ga naar je GitHub repository > Settings > Webhooks
2. Klik "Add webhook"
3. Payload URL: http://JENKINS_SERVER_IP:8080/github-webhook/
4. Content type: application/json
5. Trigger: Just the push event
6. Klik "Add webhook"

[Screenshot: GitHub webhook configuratie]


## Opruimen

BELANGRIJK: AWS kost geld! Als je klaar bent, ruim alles op.

### Infrastructuur verwijderen

```bash
cd ~/cicd-aws-terraform/terraform

# Verwijder alle resources
terraform destroy
```

Type "yes" om te bevestigen. Dit verwijdert:
- Beide EC2 instances
- Beide Security Groups
- Beide Elastic IPs

### Controleren in AWS Console

Log in op AWS en controleer:
1. EC2 > Instances - zou leeg moeten zijn
2. EC2 > Elastic IPs - zou leeg moeten zijn
3. EC2 > Security Groups - alleen de default zou over moeten zijn

[Screenshot: Lege EC2 console]


## Veelvoorkomende Problemen

### SSH verbinding werkt niet

Probleem: "Permission denied" of "Connection refused"

Oplossingen:
- Controleer of de key permissies 600 heeft: `chmod 600 ~/.ssh/klinkr-key.pem`
- Controleer of je de juiste key naam gebruikt
- Wacht een minuut na terraform apply voordat je verbindt

### Ansible kan geen verbinding maken

Probleem: "unreachable"

Oplossingen:
- Controleer of inventory.ini de juiste IP adressen bevat
- Test eerst met: `ssh -i ~/.ssh/klinkr-key.pem admin@IP_ADRES`
- Controleer security groups in AWS (poort 22 moet open zijn)

### Jenkins plugins installeren mislukt

Probleem: Plugin installation failed

Oplossingen:
- Wacht en probeer opnieuw (soms zijn mirrors traag)
- Installeer plugins handmatig via de web interface

### Docker container start niet

Probleem: Container exits immediately

Oplossingen:
- Bekijk logs: `sudo docker logs flask-app`
- Controleer of de Dockerfile correct is
- Controleer of requirements.txt alle dependencies bevat

### Terraform destroy werkt niet

Probleem: Resources worden niet verwijderd

Oplossingen:
- Probeer opnieuw met: `terraform destroy -auto-approve`
- Verwijder handmatig via AWS Console
- Controleer of er geen afhankelijke resources zijn


## Samenvatting

Je hebt nu een volledig werkende CI/CD pipeline met:

- Terraform voor infrastructure as code
- Twee EC2 servers in AWS
- Ansible voor configuratiebeheer
- Docker voor containerisatie
- Jenkins voor automatische deployments
- Een Flask webapplicatie

Wanneer je code pusht naar GitHub, kan Jenkins automatisch:
1. De nieuwe code ophalen
2. Een nieuwe Docker image bouwen
3. De container herstarten
4. Een health check uitvoeren

Dit is dezelfde workflow die professionele DevOps teams gebruiken!
