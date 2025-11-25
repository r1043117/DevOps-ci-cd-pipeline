# Terraform Setup - App Server Infrastructure

## Overview

This Terraform configuration creates the infrastructure for **VM 1 (App Server)** on AWS. The App Server will host a Flask application running in Docker.

### What Gets Created

- **1 EC2 Instance** (Debian 12, t3.micro, 20GB disk)
- **1 Security Group** (Firewall with ports: SSH, HTTP, HTTPS, Flask)
- **1 Elastic IP** (Public IP address for accessing the server)

### Architecture Diagram

```
Internet
   |
   v
[Security Group] --> Ports: 22 (SSH), 80 (HTTP), 443 (HTTPS), 5000 (Flask)
   |
   v
[EC2 Instance: App Server]
   - OS: Debian 12
   - Size: t3.micro (2 vCPUs, 1GB RAM)
   - Disk: 20GB (for Docker images)
   - Will run: Docker, Git, Python/Flask
```

---

## Prerequisites

Before you begin, make sure you have:

### 1. AWS Account
- Free tier eligible account
- Access to AWS Console

### 2. AWS CLI Installed and Configured
```bash
# Check if AWS CLI is installed
aws --version

# Configure AWS CLI with your credentials
aws configure
```

You'll need:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., `eu-west-1`)

### 3. Terraform Installed
```bash
# Check if Terraform is installed
terraform --version
```

If not installed, download from: https://www.terraform.io/downloads

### 4. SSH Key Pair in AWS

**IMPORTANT:** You must create an SSH key pair in AWS **before** running Terraform.

1. Go to AWS Console → EC2 → Network & Security → Key Pairs
2. Click "Create Key Pair"
3. Name it (e.g., `klinkr-key` or `my-key`)
4. Select `.pem` format (for SSH)
5. Click "Create" and **save the `.pem` file** to `C:\Users\YourName\.ssh\`
6. Remember the name (you'll need it in `terraform.tfvars`)

---

## Step-by-Step Setup Guide

### Step 1: Navigate to Terraform Directory

```bash
cd ~/cicd-aws-terraform/terraform
```

### Step 2: Create Your Configuration File

Copy the example configuration file and customize it with your values:

```bash
# Copy the example file
copy terraform.tfvars.example terraform.tfvars
```

Now edit `terraform.tfvars` with your actual values:


# AWS Region - Choose your preferred region
aws_region = "eu-west-1"

# SSH Key Name - Use the key pair you created in AWS
ssh_key_name = "klinkr-key"  # Change this to YOUR key name

# SSH Access - Your public IP or allow all (for testing)
allowed_ssh_cidr = "0.0.0.0/0"  # For security, replace with "YOUR_IP/32"

# Domain (optional - for future use)
domain_name = "yourdomain.com"

# cPanel (optional - for future DNS automation)
cpanel_url = "https://your-cpanel-host:2083"
cpanel_username = "your-username"
cpanel_api_token = "YOUR-API-TOKEN-HERE"
```

**Security Tip:** To restrict SSH access to only your IP:
1. Visit https://whatismyipaddress.com
2. Copy your IP address
3. Set `allowed_ssh_cidr = "YOUR_IP/32"` (replace YOUR_IP)

### Step 3: Initialize Terraform

This downloads the AWS provider plugin:

```bash
terraform init
```

**Expected Output:**
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...

Terraform has been successfully initialized!
```

---

## Test Commands

Before deploying, **always test** your configuration to catch errors early.

### 1. Validate Configuration Syntax

Check if your `.tf` files have correct syntax:

```bash
terraform validate
```

**Expected Output:**
```
Success! The configuration is valid.
```

**If you see errors:** Read the error message carefully - it will tell you which file and line number has the problem.

### 2. Format Code (Optional)

Auto-format your Terraform files to follow best practices:

```bash
terraform fmt
```

This automatically fixes indentation and spacing.

### 3. Preview Changes (Dry Run)

See what Terraform will create **without actually creating it**:

```bash
terraform plan
```

**What to look for:**
- Check the output shows `+ create` for resources
- Verify the instance type is `t3.micro` (free tier)
- Verify the region is correct
- Verify the SSH key name is correct

**Expected Output Summary:**
```
Plan: 2 to add, 0 to change, 0 to destroy.
```

This means Terraform will create:
- 1 EC2 instance (App Server)
- 1 Security Group (Firewall)

### 4. Save the Plan (Optional)

You can save the plan to a file and review it later:

```bash
terraform plan -out=tfplan

# Review the saved plan
terraform show tfplan
```

---

## Deploy Commands

Once you've tested and are satisfied with the plan, deploy the infrastructure.

### Deploy the Infrastructure

```bash
terraform apply
```

**What happens:**
1. Terraform shows you the plan again
2. You must type `yes` to confirm
3. Terraform creates the resources on AWS (takes ~2-3 minutes)

**Alternative:** Auto-approve (skip confirmation):
```bash
terraform apply -auto-approve
```

**⚠️ Warning:** Only use `-auto-approve` if you're certain about the changes!

### Monitor the Deployment

You'll see output like:
```
aws_security_group.app_server_sg: Creating...
aws_security_group.app_server_sg: Creation complete after 3s
aws_instance.app_server: Creating...
aws_instance.app_server: Still creating... [10s elapsed]
aws_instance.app_server: Still creating... [20s elapsed]
aws_instance.app_server: Creation complete after 35s

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

app_server_id = "i-0123456789abcdef0"
app_server_public_ip = "54.123.45.67"
ssh_connection_command = "ssh -i ~/.ssh/klinkr-key.pem admin@54.123.45.67"
flask_app_url = "http://54.123.45.67:5000"
```

---

## Understanding the Outputs

After deployment, Terraform displays useful information:

| Output | Description | Example |
|--------|-------------|---------|
| `app_server_id` | Unique AWS identifier for the VM | `i-0123456789abcdef0` |
| `app_server_public_ip` | Public IP address to access the server | `54.123.45.67` |
| `app_server_private_ip` | Internal AWS IP (not accessible from internet) | `172.31.x.x` |
| `ssh_connection_command` | Command to SSH into the server | `ssh -i ~/.ssh/klinkr-key.pem admin@54.123.45.67` |
| `flask_app_url` | URL where Flask app will be accessible | `http://54.123.45.67:5000` |
| `debian_ami_used` | The Debian 12 image ID that was used | `ami-0abcdef123456789` |

### View Outputs Anytime

```bash
# Show all outputs
terraform output

# Show specific output
terraform output app_server_public_ip
```

---

## Verify Deployment

### 1. Check AWS Console

1. Log in to AWS Console
2. Go to **EC2 → Instances**
3. You should see an instance named **"app-server"** with status **"Running"**

### 2. Test SSH Connection

Use the SSH command from the outputs:

```bash
# Replace with your actual command from outputs
ssh -i ~/.ssh/klinkr-key.pem admin@54.123.45.67
```

**First Time Connection:**
- You'll see a warning about host authenticity - type `yes`
- If it asks for a password, something is wrong (SSH keys should work without password)

**If SSH fails:**
- Check the `.pem` file permissions: `chmod 400 ~/.ssh/klinkr-key.pem` (on Linux/Mac)
- Verify you're using the correct key name
- Check your `allowed_ssh_cidr` setting - make sure your IP is allowed

### 3. Check Server Info

Once connected via SSH, verify the server:

```bash
# Check OS version
cat /etc/os-release

# Check disk space (should show 20GB)
df -h

# Check system resources
free -h
```

---

## Making Changes

If you need to modify the infrastructure:

### 1. Edit Configuration Files

Edit the relevant `.tf` files:
- `main.tf` - Change instance type, disk size, security rules
- `terraform.tfvars` - Change region, key name, IP restrictions

### 2. Preview Changes

```bash
terraform plan
```

Look for:
- `~` (tilde) = modify in place
- `+` (plus) = create new resource
- `-` (minus) = destroy resource
- `-/+` = destroy and recreate (causes downtime!)

### 3. Apply Changes

```bash
terraform apply
```

**⚠️ Warning:** Some changes require replacing the EC2 instance (destroys and recreates):
- Changing instance type
- Changing AMI
- Changing key pair

This causes **downtime** and **data loss** on the VM!

---

## Useful Commands

```bash
# Show current state
terraform show

# List all resources managed by Terraform
terraform state list

# Get detailed info about a specific resource
terraform state show aws_instance.app_server

# Refresh state (sync with AWS)
terraform refresh

# See execution plan with detailed logging
TF_LOG=DEBUG terraform plan
```

---

## Cleanup / Destroy Infrastructure

When you're done and want to **delete everything** (to avoid AWS charges):

### ⚠️ WARNING: This is PERMANENT and IRREVERSIBLE!

```bash
# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy
```

Type `yes` when prompted.

**What gets deleted:**
- EC2 instance (App Server) - **ALL DATA WILL BE LOST**
- Security Group
- All configurations

**What is NOT deleted:**
- Terraform state files (`.tfstate`)
- Your SSH key pair in AWS
- Your local configuration files

---

## Troubleshooting

### Error: "No valid credential sources found"

**Problem:** AWS CLI is not configured.

**Solution:**
```bash
aws configure
```
Enter your AWS Access Key ID and Secret Access Key.

---

### Error: "InvalidKeyPair.NotFound"

**Problem:** The SSH key pair doesn't exist in AWS, or the name is wrong.

**Solution:**
1. Check AWS Console → EC2 → Key Pairs
2. Verify the key name matches `ssh_key_name` in `terraform.tfvars`
3. Make sure you're in the correct AWS region

---

### Error: "Error launching source instance: VPCIdNotSpecified"

**Problem:** Your AWS account doesn't have a default VPC.

**Solution:** Create a default VPC or specify a VPC ID in the configuration (advanced).

---

### SSH Permission Denied

**Problem:** SSH key file has wrong permissions.

**Solution (Linux/Mac):**
```bash
chmod 400 ~/.ssh/your-key.pem
```

**Solution (Windows PowerShell):**
```powershell
icacls C:\Users\YourName\.ssh\your-key.pem /inheritance:r /grant:r "%username%:R"
```

---

### Terraform state locked

**Problem:** Another Terraform process is running, or a previous run crashed.

**Solution:**
```bash
# ONLY if you're certain no other terraform is running
terraform force-unlock LOCK_ID
```

(Replace `LOCK_ID` with the ID shown in the error message)

---

## Next Steps

Once your App Server infrastructure is deployed:

1. **Configure the server with Ansible:**
   - Install Docker
   - Install Git
   - Install Python and Flask
   - Deploy the Flask application

2. **Create VM 2 (Jenkins Server):**
   - Add second EC2 instance to Terraform configuration
   - Configure Jenkins for CI/CD

3. **Set up the CI/CD pipeline:**
   - Configure Jenkins jobs
   - Set up webhooks
   - Automate deployments

---

## File Structure

```
terraform/
├── README.md                    # This file
├── provider.tf                  # AWS provider configuration
├── main.tf                      # EC2 instance and security group
├── outputs.tf                   # Output values after deployment
├── terraform.tfvars.example     # Template for configuration
├── terraform.tfvars             # Your actual configuration (not in git)
└── .terraform/                  # Downloaded provider plugins (not in git)
```

---

## Important Notes

1. **Never commit `terraform.tfvars`** - It contains sensitive information (API keys)
2. **Never commit `terraform.tfstate`** - It can contain sensitive data
3. **Always run `terraform plan` before `terraform apply`**
4. **Keep your `.pem` file safe** - If you lose it, you can't access your server
5. **Monitor AWS costs** - Even t3.micro can have charges if not in free tier

---

## Support

If you encounter issues:

1. Check the **Troubleshooting** section above
2. Review Terraform documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
3. Check AWS Console for resource status
4. Review Terraform logs with: `TF_LOG=DEBUG terraform apply`

---

**Last Updated:** November 2025
**Terraform Version:** ~> 1.0
**AWS Provider Version:** ~> 5.0
