# WSL Setup Guide - Terraform

This guide will help you set up and run Terraform from WSL Debian.

---

## Step 1: Check/Install WSL Debian

### Check if WSL is installed

Open PowerShell and run:

```powershell
wsl --list --verbose
```

**If you see Debian listed** - Great! Skip to Step 2.

**If WSL is not installed:**

```powershell
# Install WSL with Debian
wsl --install -d Debian
```

After installation, restart your computer.

---

## Step 2: Access Your Project in WSL

Open WSL Debian terminal and navigate to your project:

```bash
# Your Windows C:\ drive is accessible at /mnt/c/
cd /mnt/c/Users/deruw/cicd-aws-terraform/terraform

# Verify you're in the right place
ls -la
```

**Expected output:** You should see `main.tf`, `provider.tf`, `outputs.tf`, etc.

---

## Step 3: Install Terraform in WSL

```bash
# Update package list
sudo apt update

# Install required packages
sudo apt install -y wget unzip

# Download Terraform (check https://www.terraform.io/downloads for latest version)
wget https://releases.hashicorp.com/terraform/1.10.3/terraform_1.10.3_linux_amd64.zip

# Unzip
unzip terraform_1.10.3_linux_amd64.zip

# Move to PATH
sudo mv terraform /usr/local/bin/

# Clean up
rm terraform_1.10.3_linux_amd64.zip

# Verify installation
terraform --version
```

**Expected output:**
```
Terraform v1.10.3
```

---

## Step 4: Install AWS CLI in WSL

```bash
# Download AWS CLI installer (using wget)
wget https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -O awscliv2.zip

# Unzip
unzip awscliv2.zip

# Install
sudo ./aws/install

# Clean up
rm -rf aws awscliv2.zip

# Verify installation
aws --version
```

**Expected output:**
```
aws-cli/2.x.x Python/3.x.x Linux/...
```

**Note:** If you prefer to use `curl` instead of `wget`, first install it:
```bash
sudo apt update && sudo apt install -y curl
# Then use: curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
```

---

## Step 5: Configure AWS CLI

```bash
aws configure
```

You'll be prompted for:

1. **AWS Access Key ID**: (from your AWS account)
2. **AWS Secret Access Key**: (from your AWS account)
3. **Default region name**: `eu-west-1` (or your preferred region)
4. **Default output format**: `json`

**To get AWS credentials:**
1. Log in to AWS Console
2. Go to: IAM → Users → Your User → Security Credentials
3. Click "Create Access Key"
4. Copy the Access Key ID and Secret Access Key

**Test AWS connection:**
```bash
aws sts get-caller-identity
```

If this returns your account info, AWS CLI is configured correctly!

---

## Step 6: Set Up SSH Keys in WSL

Your SSH keys need to be accessible from WSL.

**Option 1: Copy from Windows to WSL** (Recommended)

```bash
# Create .ssh directory in WSL home
mkdir -p ~/.ssh

# Copy your .pem file from Windows
cp /mnt/c/Users/deruw/.ssh/klinkr-key.pem ~/.ssh/

# Set correct permissions (IMPORTANT!)
chmod 600 ~/.ssh/klinkr-key.pem
chmod 700 ~/.ssh
```

**Option 2: Use Windows SSH keys directly**

```bash
# Just reference the Windows path when needed
# Example: ssh -i /mnt/c/Users/deruw/.ssh/klinkr-key.pem admin@<IP>
```

---

## Step 7: Prepare Terraform Configuration

```bash
# Navigate to terraform directory
cd /mnt/c/Users/deruw/cicd-aws-terraform/terraform

# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values (use nano or vim)
nano terraform.tfvars
```

Update these values:
- `aws_region` - Your AWS region
- `ssh_key_name` - Your SSH key pair name in AWS (e.g., "klinkr-key")
- `allowed_ssh_cidr` - Your IP or "0.0.0.0/0" for testing

**Save and exit:**
- In nano: `Ctrl+O`, `Enter`, `Ctrl+X`
- In vim: `Esc`, `:wq`, `Enter`

---

## Step 8: Initialize Terraform

```bash
# Make sure you're in the terraform directory
cd /mnt/c/Users/deruw/cicd-aws-terraform/terraform

# Initialize Terraform
terraform init
```

**Expected output:**
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...

Terraform has been successfully initialized!
```

---

## Step 9: Validate Configuration

```bash
# Check syntax
terraform validate
```

**Expected output:**
```
Success! The configuration is valid.
```

---

## Step 10: Test Plan

```bash
# Preview what will be created
terraform plan
```

**What to check:**
- ✅ No errors
- ✅ Shows `Plan: 2 to add, 0 to change, 0 to destroy`
- ✅ Resource names look correct (app_server, app_server_sg)
- ✅ Region is correct
- ✅ SSH key name is correct

**If you see errors:**
- Check `terraform.tfvars` has correct values
- Verify AWS credentials are configured: `aws sts get-caller-identity`
- Make sure SSH key pair exists in AWS Console

---

## Step 11: Deploy (When Ready)

**Only run this when you're ready to create resources on AWS!**

```bash
terraform apply
```

Type `yes` when prompted.

**Expected output:**
```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

app_server_id = "i-xxxxx"
app_server_public_ip = "xx.xx.xx.xx"
ssh_connection_command = "ssh -i ~/.ssh/klinkr-key.pem admin@xx.xx.xx.xx"
flask_app_url = "http://xx.xx.xx.xx:5000"
```

---

## Step 12: Test SSH Connection

Use the SSH command from the output:

```bash
# Update path to your SSH key if needed
ssh -i ~/.ssh/klinkr-key.pem admin@<public_ip>
```

If connected successfully, you're all set! 🎉

---

## Common Issues

### Issue: "Permission denied (publickey)"

**Solution:**
```bash
# Check key permissions
ls -la ~/.ssh/klinkr-key.pem

# Should show: -rw------- (600)
# If not, fix with:
chmod 600 ~/.ssh/klinkr-key.pem
```

---

### Issue: "Error: No valid credential sources found"

**Solution:**
```bash
# Reconfigure AWS CLI
aws configure

# Test connection
aws sts get-caller-identity
```

---

### Issue: Terraform can't find terraform.tfvars

**Solution:**
```bash
# Make sure you're in the terraform directory
pwd
# Should show: /mnt/c/Users/deruw/cicd-aws-terraform/terraform

# Check file exists
ls -la terraform.tfvars
```

---

## Useful WSL Commands

```bash
# Check current directory
pwd

# Go to Windows user folder
cd /mnt/c/Users/deruw

# Go to project
cd /mnt/c/Users/deruw/cicd-aws-terraform/terraform

# Edit files
nano filename.tf
# or
vim filename.tf

# View file contents
cat filename.tf

# Check running processes
ps aux | grep terraform
```

---

## Working Directory Recommendation

**Option 1: Work from Windows mount** (Easier for editing in VS Code)
```bash
cd /mnt/c/Users/deruw/cicd-aws-terraform/terraform
```

**Option 2: Copy to WSL home** (Slightly faster)
```bash
# Copy entire project to WSL
cp -r /mnt/c/Users/deruw/cicd-aws-terraform ~/cicd-aws-terraform
cd ~/cicd-aws-terraform/terraform
```

**I recommend Option 1** - You can edit files in Windows VS Code and run commands in WSL.

---

## Next Steps

Once Terraform works in WSL:
1. ✅ Terraform infrastructure is ready
2. ⏭️ Set up Ansible in WSL (next phase)
3. ⏭️ Configure App Server with Ansible
4. ⏭️ Deploy Flask application

---

## Quick Reference

```bash
# Navigate to project
cd /mnt/c/Users/deruw/cicd-aws-terraform/terraform

# Test configuration
terraform validate
terraform plan

# Deploy
terraform apply

# View outputs
terraform output

# Destroy (when done)
terraform destroy
```

---

**Status Check:**
- [ ] WSL Debian installed
- [ ] Terraform installed in WSL
- [ ] AWS CLI installed in WSL
- [ ] AWS credentials configured
- [ ] SSH keys accessible in WSL
- [ ] terraform.tfvars configured
- [ ] terraform init successful
- [ ] terraform validate successful
- [ ] terraform plan successful
- [ ] Ready to deploy with terraform apply

Mark each item as you complete it!
