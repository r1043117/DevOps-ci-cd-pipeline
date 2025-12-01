# CI/CD AWS Terraform Pipeline

A complete CI/CD pipeline that deploys a Flask application to AWS using Terraform, Ansible, and Jenkins.

## Architecture Overview

```
┌─────────────┐     webhook      ┌─────────────────┐     SSH      ┌─────────────────┐
│   GitHub    │ ───────────────> │  Jenkins (EC2)  │ ──────────> │  App Server     │
│  (Source)   │                  │  Port 8080      │             │  (EC2 + Docker) │
└─────────────┘                  └─────────────────┘             │  Port 80        │
                                                                  └─────────────────┘
```

## Prerequisites

Before starting this project, you need the following tools installed:

### 1. AWS CLI
Used to interact with Amazon Web Services.
```bash
# Check installation
aws --version
# Expected: aws-cli/2.x.x or higher
```

### 2. Terraform
Infrastructure as Code tool to create AWS resources.
```bash
# Check installation
terraform --version
# Expected: Terraform v1.x.x or higher
```

### 3. Ansible
Configuration management tool to set up the servers.
```bash
# Check installation
ansible --version
# Expected: ansible [core 2.x.x] or higher
```

### 4. Git
Version control for the project.
```bash
# Check installation
git --version
# Expected: git version 2.x.x or higher
```

### 5. SSH Key Pair
You need an SSH key pair registered in AWS to access your EC2 instances.

---

## AWS Setup

### Step 1: Configure AWS Credentials

Run the AWS configure command and enter your credentials:
```bash
aws configure
```

You will be prompted for:
```
AWS Access Key ID [None]: YOUR_ACCESS_KEY
AWS Secret Access Key [None]: YOUR_SECRET_KEY
Default region name [None]: eu-west-1
Default output format [None]: json
```

**Where to get credentials:**
1. Log in to AWS Console
2. Go to IAM → Users → Your User → Security credentials
3. Create Access Key (if you don't have one)

**Verify configuration:**
```bash
aws sts get-caller-identity
```

### Step 2: Create or Import SSH Key Pair

**Option A: Create new key pair in AWS Console**
1. Go to EC2 → Key Pairs → Create key pair
2. Name: `klinkr-key` (or your preferred name)
3. Type: RSA
4. Format: .pem
5. Download and save to `~/.ssh/klinkr-key.pem`

**Option B: Import existing key**
1. Generate locally: `ssh-keygen -t rsa -b 4096 -f ~/.ssh/klinkr-key`
2. Import public key to AWS EC2 → Key Pairs → Import

**Set correct permissions:**
```bash
chmod 400 ~/.ssh/klinkr-key.pem
```

**Verify key exists:**
```bash
ls -la ~/.ssh/klinkr-key.pem
```

---

## Project Structure

```
cicd-aws-terraform/
├── terraform/          # Infrastructure as Code
├── ansible/            # Server configuration
├── flask-app/          # The application to deploy
├── Jenkinsfile         # CI/CD pipeline definition
└── README.md           # This file
```
