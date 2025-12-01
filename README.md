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

## Project Structure

```
cicd-aws-terraform/
├── terraform/          # Infrastructure as Code
├── ansible/            # Server configuration
├── flask-app/          # The application to deploy
├── Jenkinsfile         # CI/CD pipeline definition
└── README.md           # This file
```
