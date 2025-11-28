# DevOps CI/CD Pipeline

Automated infrastructure deployment using Terraform, Ansible, and Jenkins.

## What This Project Creates

| Component | Description |
|-----------|-------------|
| **VM1 - App Server** | Debian 12 EC2 running Flask app in Docker |
| **VM2 - Jenkins** | Debian 12 EC2 running Jenkins CI/CD |
| **Pipeline** | Auto-deploys Flask app on git push (git pull → docker build → deploy) |

---

## Prerequisites

### 1. AWS Account
- Create free account at [aws.amazon.com](https://aws.amazon.com)
- Note: Resources are free-tier eligible

### 2. Install Required Tools

**On Windows (WSL recommended):**
```bash
# Install WSL (PowerShell as Admin)
wsl --install -d Debian
```

**In WSL/Linux:**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Install Ansible
sudo apt install -y ansible

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Git
sudo apt install -y git
```

### 3. AWS Credentials

Create IAM user with EC2 permissions:
1. AWS Console → IAM → Users → Add user
2. Attach policy: `AmazonEC2FullAccess`
3. Create access key and save it

Configure AWS CLI:
```bash
aws configure
# Enter: Access Key ID, Secret Key, Region (eu-west-1), Output (json)
```

### 4. SSH Key Pair

Create in AWS Console:
1. EC2 → Key Pairs → Create key pair
2. Name: `my-key` (remember this name)
3. Format: `.pem`
4. Save the downloaded file to `~/.ssh/`

```bash
chmod 400 ~/.ssh/my-key.pem
```

---

## Quick Start

### Step 1: Clone Repository

```bash
git clone https://github.com/r1043117/DevOps-ci-cd-pipeline.git
cd DevOps-ci-cd-pipeline
```

### Step 2: Configure Terraform

```bash
cd terraform

# Create your config file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

Set these values in `terraform.tfvars`:
```hcl
aws_region   = "eu-west-1"
ssh_key_name = "my-key"  # Your AWS key pair name
```

### Step 3: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Preview what will be created
terraform plan

# Create the infrastructure
terraform apply
# Type 'yes' when prompted

# Save the output IPs!
terraform output
```

### Step 4: Configure Ansible

```bash
cd ../ansible

# Create inventory file
cp inventory.ini.example inventory.ini

# Edit with your IPs from terraform output
nano inventory.ini
```

Update the IPs in `inventory.ini`:
```ini
[app_servers]
vm1 ansible_host=YOUR_APP_SERVER_IP ansible_user=admin ansible_ssh_private_key_file=~/.ssh/my-key.pem

[jenkins_servers]
vm2 ansible_host=YOUR_JENKINS_SERVER_IP ansible_user=admin ansible_ssh_private_key_file=~/.ssh/my-key.pem
```

### Step 5: Create Vault Password

```bash
# Create vault password file
echo "your-secret-password" > .vault_pass.txt
chmod 600 .vault_pass.txt

# Edit vault to set Jenkins password
ansible-vault edit group_vars/all/vault.yml
# Set: vault_jenkins_admin_pass: "your-jenkins-password"
```

### Step 6: Run Ansible

```bash
# Provision all servers
ansible-playbook playbooks/site.yml
```

### Step 7: Access Your Services

After Ansible completes:

| Service | URL |
|---------|-----|
| Flask App | `http://APP_SERVER_IP` (port 80) |
| Jenkins | `http://JENKINS_SERVER_IP:8080` |

---

## Setting Up Jenkins Pipeline

### Add SSH Credentials in Jenkins

1. Open Jenkins: `http://JENKINS_IP:8080`
2. Login with credentials from vault (username: `admin`)
3. Go to **Manage Jenkins** → **Credentials**
4. Click **(global)** → **Add Credentials**
5. Fill in:
   - Kind: **SSH Username with private key**
   - ID: `vm1-ssh-key`
   - Description: `SSH key for App Server`
   - Username: `admin`
   - Private Key: **Enter directly** → paste contents of `~/.ssh/my-key.pem`
6. Click **Create**

### Create Pipeline Job

1. Click **New Item** → Name: `flask-deploy` → **Pipeline**
2. **Build Triggers** → Check **GitHub hook trigger for GITScm polling**
3. **Pipeline**:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: `https://github.com/r1043117/DevOps-ci-cd-pipeline.git`
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`
4. **Save**

### Configure GitHub Webhook

1. GitHub repo → **Settings** → **Webhooks** → **Add webhook**
2. Payload URL: `http://JENKINS_IP:8080/github-webhook/`
3. Content type: `application/json`
4. Events: Just the push event
5. **Add webhook**

### Update Jenkinsfile

Edit `Jenkinsfile` and set your App Server IP:
```groovy
environment {
    APP_SERVER = 'YOUR_APP_SERVER_IP'
    APP_USER = 'admin'
}
```

Commit and push - Jenkins will auto-deploy!

---

## How the CI/CD Pipeline Works

When you push code to GitHub:

1. **GitHub Webhook** triggers Jenkins
2. **Jenkins** SSHs to VM1 (App Server)
3. **Git Pull** fetches latest code from GitHub
4. **Docker Build** creates new image from `flask-app/`
5. **Docker Run** deploys the new container
6. **Health Check** verifies the app is running

```
┌──────────┐    push     ┌──────────┐   webhook   ┌──────────┐
│  Local   │ ─────────▶  │  GitHub  │ ──────────▶ │ Jenkins  │
│   Dev    │             │   Repo   │             │  (VM2)   │
└──────────┘             └──────────┘             └────┬─────┘
                                                       │ SSH
                                                       ▼
                                                 ┌──────────┐
                                                 │ App VM1  │
                                                 │ git pull │
                                                 │ docker   │
                                                 └──────────┘
```

---

## Project Structure

```
.
├── terraform/              # Infrastructure as Code
│   ├── main.tf            # EC2 instances, security groups
│   ├── outputs.tf         # Output values (IPs)
│   └── terraform.tfvars.example
│
├── ansible/               # Configuration Management
│   ├── playbooks/
│   │   ├── site.yml      # Master playbook
│   │   ├── docker.yml        # Docker installation
│   │   ├── jenkins.yml       # Jenkins installation
│   │   └── deploy-flask.yml  # Flask app deployment
│   ├── group_vars/
│   │   └── all/
│   │       ├── vars.yml  # Variables
│   │       └── vault.yml # Encrypted secrets
│   └── inventory.ini.example
│
├── flask-app/             # Application
│   ├── app.py            # Flask application
│   ├── templates/        # HTML templates
│   ├── static/css/       # Stylesheets
│   └── Dockerfile
│
└── Jenkinsfile           # CI/CD Pipeline
```

---

## Common Commands

```bash
# Terraform
terraform plan          # Preview changes
terraform apply         # Deploy infrastructure
terraform destroy       # Delete everything
terraform output        # Show IPs

# Ansible
ansible-playbook playbooks/site.yml           # Run all playbooks
ansible-playbook playbooks/jenkins.yml        # Run only Jenkins
ansible all -m ping                            # Test connections
ansible-vault edit group_vars/all/vault.yml   # Edit secrets

# Git - trigger CI/CD pipeline
git add -A && git commit -m "message" && git push

# Trigger build without changes (empty commit)
git commit --allow-empty -m "Trigger build" && git push
```

---

## Cleanup

To delete all AWS resources and stop charges:

```bash
cd terraform
terraform destroy
# Type 'yes' to confirm
```

---

## Files to Update After Redeploy

After each `terraform destroy` and `terraform apply`, update these files with new IPs:

| File | What to Update |
|------|----------------|
| `ansible/inventory.ini` | VM1 and VM2 IP addresses |
| `Jenkinsfile` | APP_SERVER IP (line 9) |
| GitHub Webhook | Jenkins URL with new IP (e.g., `http://NEW_JENKINS_IP:8080/github-webhook/`) |

---

## Troubleshooting

### SSH Connection Failed
```bash
# Check key permissions
chmod 400 ~/.ssh/my-key.pem

# Test SSH manually
ssh -i ~/.ssh/my-key.pem admin@IP_ADDRESS
```

### Ansible Vault Error
```bash
# Make sure vault password file exists
cat ansible/.vault_pass.txt

# Re-encrypt vault if needed
ansible-vault rekey group_vars/all/vault.yml
```

### Jenkins Not Accessible
```bash
# Check if Jenkins is running
ssh admin@JENKINS_IP "sudo systemctl status jenkins"

# Check security group allows port 8080
```

---

## For Fellow Students

To work on this project:

1. Get added as collaborator on GitHub
2. Clone the repo
3. Set up your own AWS credentials
4. Create your own SSH key pair in AWS
5. Follow the Quick Start steps above

Each person needs their own:
- AWS account/credentials
- SSH key pair
- `terraform.tfvars` file
- `inventory.ini` file
- `.vault_pass.txt` file

---

## License

Educational project for DevOps learning.
