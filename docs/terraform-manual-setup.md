# Terraform AWS Infrastructure Setup Guide

A step-by-step guide for deploying AWS infrastructure using Terraform.

---

## What This Creates

This Terraform configuration deploys:

| Resource | Purpose |
|----------|---------|
| **App Server (VM1)** | Debian 12 EC2 instance for Flask application |
| **Jenkins Server (VM2)** | Debian 12 EC2 instance for CI/CD |
| **Security Groups** | Firewall rules for both servers |
| **Elastic IPs** | Static public IPs that survive restarts |

---

## Prerequisites

### 1. AWS Account

Create a free AWS account at [aws.amazon.com](https://aws.amazon.com)

### 2. Install Terraform

**Windows (using Chocolatey):**
```powershell
choco install terraform
```

**Linux/WSL:**
```bash
# Download Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip

# Unzip and install
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installation
terraform --version
```

### 3. Install AWS CLI

**Windows:**
```powershell
choco install awscli
```

**Linux/WSL:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

---

## AWS Setup

### 1. Create IAM User

1. Go to AWS Console → **IAM** → **Users**
2. Click **"Add users"**
3. Username: `terraform-user`
4. Check **"Access key - Programmatic access"**
5. Click **"Next: Permissions"**
6. Select **"Attach policies directly"**
7. Search and select: `AmazonEC2FullAccess`
8. Click **"Next"** → **"Create user"**
9. **Important:** Copy the Access Key ID and Secret Access Key

### 2. Configure AWS CLI

```bash
aws configure
```

Enter when prompted:
```
AWS Access Key ID: YOUR_ACCESS_KEY_ID
AWS Secret Access Key: YOUR_SECRET_ACCESS_KEY
Default region name: eu-west-1
Default output format: json
```

### 3. Create SSH Key Pair

1. Go to AWS Console → **EC2** → **Key Pairs**
2. Click **"Create key pair"**
3. Name: `my-key` (remember this name)
4. Key pair type: RSA
5. Private key format: `.pem`
6. Click **"Create key pair"**
7. Save the downloaded `.pem` file to `~/.ssh/`

Set proper permissions:
```bash
chmod 400 ~/.ssh/my-key.pem
```

---

## Project Structure

```
terraform/
├── provider.tf           # AWS provider configuration
├── main.tf              # Infrastructure resources
├── outputs.tf           # Output values (IPs, URLs)
├── terraform.tfvars.example  # Example configuration
└── terraform.tfvars     # Your actual configuration (not in git)
```

---

## Configuration Files Explained

### provider.tf
Tells Terraform to use AWS and which version of the AWS plugin.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

### main.tf
Defines all your infrastructure:
- **Variables**: Customizable settings (region, SSH key name)
- **Data source**: Finds the latest Debian 12 AMI
- **Security groups**: Firewall rules
- **EC2 instances**: The actual servers
- **Elastic IPs**: Static public IP addresses

### outputs.tf
Displays useful information after deployment:
- Server IP addresses
- SSH connection commands
- Application URLs

---

## Step-by-Step Deployment

### Step 1: Create Configuration File

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
```

### Step 2: Edit Configuration

Edit `terraform.tfvars`:

```hcl
# AWS Region
aws_region = "eu-west-1"

# Your SSH key pair name (must match the key you created in AWS)
ssh_key_name = "my-key"

# SSH access restriction (optional)
allowed_ssh_cidr = "0.0.0.0/0"  # Or your IP: "1.2.3.4/32"
```

### Step 3: Initialize Terraform

Downloads the AWS provider plugin:

```bash
terraform init
```

Expected output:
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...

Terraform has been successfully initialized!
```

### Step 4: Preview Changes

See what will be created:

```bash
terraform plan
```

Review the output. You should see:
- 2 EC2 instances (app-server, jenkins-server)
- 2 Security groups
- 2 Elastic IPs

### Step 5: Apply Configuration

Create the infrastructure:

```bash
terraform apply
```

Type `yes` when prompted.

Wait 2-3 minutes for resources to be created.

### Step 6: Note the Outputs

After successful apply, you'll see:

```
Outputs:

app_server_public_ip = "52.x.x.x"
jenkins_server_public_ip = "54.x.x.x"
ssh_connection_command = "ssh -i ~/.ssh/my-key.pem admin@52.x.x.x"
jenkins_url = "http://54.x.x.x:8080"
```

**Save these values!**

---

## Connecting to Your Servers

### SSH to App Server

```bash
ssh -i ~/.ssh/my-key.pem admin@APP_SERVER_IP
```

### SSH to Jenkins Server

```bash
ssh -i ~/.ssh/my-key.pem admin@JENKINS_SERVER_IP
```

**Note:** Default username for Debian AMIs is `admin`

---

## Common Commands

| Command | Description |
|---------|-------------|
| `terraform init` | Initialize working directory |
| `terraform plan` | Preview changes |
| `terraform apply` | Create/update infrastructure |
| `terraform destroy` | Delete all infrastructure |
| `terraform output` | Show output values |
| `terraform state list` | List managed resources |
| `terraform refresh` | Update state with real infrastructure |

---

## Managing Infrastructure

### View Current State

```bash
terraform output
```

### Update Infrastructure

After changing `main.tf` or `terraform.tfvars`:

```bash
terraform plan    # Preview changes
terraform apply   # Apply changes
```

### Destroy Single Resource

```bash
terraform destroy -target=aws_instance.jenkins_server
```

### Destroy Everything

```bash
terraform destroy
```

Type `yes` to confirm.

---

## Cost Information

### Free Tier Eligible (12 months)

- **EC2 t3.micro**: 750 hours/month free
- **EBS storage**: 30 GB free
- **Elastic IPs**: Free when attached to running instance

### Costs When Not in Free Tier

| Resource | Cost |
|----------|------|
| t3.micro instance | ~$0.0104/hour (~$7.50/month) |
| Elastic IP (attached) | Free |
| Elastic IP (unattached) | $0.005/hour |
| EBS gp3 storage | $0.08/GB/month |

**Tip:** Always run `terraform destroy` when not using the infrastructure to avoid charges.

---

## Troubleshooting

### Error: No credentials found

```
Error: No valid credential sources found
```

**Solution:** Run `aws configure` and enter your credentials.

### Error: Key pair does not exist

```
Error: InvalidKeyPair.NotFound
```

**Solution:**
1. Check key pair name in AWS Console → EC2 → Key Pairs
2. Update `ssh_key_name` in `terraform.tfvars`

### Error: Permission denied (SSH)

```
Permission denied (publickey)
```

**Solution:**
```bash
# Fix key permissions
chmod 400 ~/.ssh/my-key.pem

# Use correct username (admin for Debian)
ssh -i ~/.ssh/my-key.pem admin@IP_ADDRESS
```

### Error: Resource already exists

```
Error: error creating Security Group: InvalidGroup.Duplicate
```

**Solution:**
```bash
# Import existing resource or delete manually
terraform import aws_security_group.app_server_sg sg-xxxxxxxx

# Or delete in AWS Console and re-apply
```

### State file issues

```bash
# Refresh state from actual infrastructure
terraform refresh

# If state is corrupted, you may need to:
rm terraform.tfstate
rm terraform.tfstate.backup
terraform import aws_instance.app_server i-xxxxxxxxx
```

---

## Security Best Practices

1. **Restrict SSH access**: Change `allowed_ssh_cidr` to your IP
   ```hcl
   allowed_ssh_cidr = "YOUR_PUBLIC_IP/32"
   ```

2. **Never commit credentials**:
   - Keep `terraform.tfvars` in `.gitignore`
   - Never put AWS keys in Terraform files

3. **Use IAM roles for production**: Instead of access keys

4. **Enable state locking**: Use S3 backend with DynamoDB for team use

5. **Review security groups**: Only open necessary ports

---

## File Reference

### terraform.tfvars (Example)

```hcl
# AWS Configuration
aws_region   = "eu-west-1"
ssh_key_name = "my-key"

# Security
allowed_ssh_cidr = "0.0.0.0/0"
```

### Quick Reference

| Setting | Description | Example |
|---------|-------------|---------|
| `aws_region` | AWS region to deploy in | `eu-west-1` (Ireland) |
| `ssh_key_name` | Name of EC2 key pair | `my-key` |
| `allowed_ssh_cidr` | IP range for SSH access | `0.0.0.0/0` or `1.2.3.4/32` |

---

## Summary

1. Install Terraform and AWS CLI
2. Create IAM user with EC2 permissions
3. Configure AWS CLI credentials
4. Create SSH key pair in AWS
5. Copy and edit `terraform.tfvars`
6. Run `terraform init`
7. Run `terraform plan` to preview
8. Run `terraform apply` to create
9. Connect via SSH using outputted commands
10. Run `terraform destroy` when done
