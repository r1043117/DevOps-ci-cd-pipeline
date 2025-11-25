# Ansible Configuration - App Server Automation

## Overview

This Ansible configuration **automates the setup and deployment** of VM1 (App Server) that was created using Terraform. Instead of manually installing software via SSH, Ansible does everything automatically.

### What This Ansible Setup Does

1. **Installs Docker** - For running containerized applications
2. **Installs Git** - For cloning code repositories
3. **Installs Python & Flask** - For running the Flask application
4. **Deploys Flask App** - Pulls code and runs the application
5. **Manages Secrets** - Uses Ansible Vault to encrypt sensitive data

---

## Prerequisites

Before using Ansible, ensure you have:

### 1. VM1 Running (Created by Terraform)
- EC2 instance must be running
- You need the **public IP address** from Terraform outputs
- SSH key (`.pem` file) must be accessible

**Get VM1 IP address:**
```bash
cd ../terraform
terraform output app_server_public_ip
```

### 2. Ansible Installed on Your Computer

**Check if installed:**
```bash
ansible --version
```

**Install Ansible (if needed):**

**Windows (using WSL - Windows Subsystem for Linux):**
```bash
# Install WSL first, then in WSL terminal:
sudo apt update
sudo apt install ansible -y
```

**Windows (using Python pip):**
```bash
pip install ansible
```

**Linux (Debian/Ubuntu):**
```bash
sudo apt update
sudo apt install ansible -y
```

**Mac:**
```bash
brew install ansible
```

### 3. Python Installed
Ansible requires Python 3.8+

```bash
python --version
# or
python3 --version
```

### 4. SSH Access to VM1
Test that you can SSH into VM1:
```bash
ssh -i ~/.ssh/your-key.pem admin@YOUR_VM1_IP
```

---

## Directory Structure

```
ansible/
├── README.md                    # This file - documentation
├── ansible.cfg                  # Ansible configuration settings
├── inventory.ini                # List of servers to manage (VM1)
├── .vault_pass.txt             # Vault password file (NOT in Git!) 🔒
├── .gitignore                  # Prevents committing secrets
│
├── group_vars/                 # Variables for all servers
│   └── all/
│       ├── vars.yml            # Public variables (safe to commit)
│       └── vault.yml           # Encrypted secrets (encrypted, safe to commit) 🔒
│
└── playbooks/                  # Automation scripts
    ├── site.yml                # Master playbook (runs all others)
    ├── docker.yml              # Install and configure Docker
    ├── git-python.yml          # Install Git and Python
    └── deploy-flask.yml        # Deploy Flask application
```

---

## Understanding Each File

### **ansible.cfg** - Configuration File
**Purpose:** Tells Ansible how to connect to servers and behave.

**What it contains:**
- Where to find the inventory file
- Default SSH user (admin for Debian)
- SSH key location
- Where to find vault password file

**Think of it as:** Global settings for Ansible

---

### **inventory.ini** - Server List
**Purpose:** Lists all servers Ansible should manage.

**What it contains:**
- VM1's IP address
- Connection details (SSH key, username)
- Server groups (e.g., `[app_servers]`)

**Example:**
```ini
[app_servers]
vm1 ansible_host=54.123.45.67 ansible_user=admin
```

**Think of it as:** Phone book of servers

---

### **group_vars/all/vars.yml** - Public Variables
**Purpose:** Store non-sensitive configuration values.

**What it contains:**
- Application name
- Port numbers
- Package versions
- File paths

**Why separate file?** Makes playbooks cleaner and reusable.

**Example:**
```yaml
app_name: flask-app
app_port: 5000
docker_version: latest
```

**Think of it as:** Public configuration settings

---

### **group_vars/all/vault.yml** - Encrypted Secrets
**Purpose:** Store sensitive data (passwords, keys, tokens) encrypted.

**What it contains:**
- Flask SECRET_KEY
- API tokens
- Passwords
- Any sensitive credentials

**Why encrypted?** Safe to commit to Git - can't be read without vault password.

**Example (encrypted):**
```yaml
$ANSIBLE_VAULT;1.1;AES256
66386439653765653836356534623865636134613639356438343534626435646234
...
```

**Think of it as:** Encrypted password vault

---

### **.vault_pass.txt** - Vault Password File
**Purpose:** Contains the password to decrypt `vault.yml`.

**What it contains:**
- Single line: your vault password

**⚠️ CRITICAL:**
- **NEVER commit this to Git!**
- Must be in `.gitignore`
- Keep secure (use password manager)

**Example:**
```
MySecureVaultPassword123!
```

**Think of it as:** Key to your encrypted vault

---

### **playbooks/site.yml** - Master Playbook
**Purpose:** Main entry point that runs all other playbooks in order.

**What it does:**
1. Runs `docker.yml` (install Docker)
2. Runs `git-python.yml` (install Git and Python)
3. Runs `deploy-flask.yml` (deploy application)

**Think of it as:** Master recipe that includes all other recipes

---

### **playbooks/docker.yml** - Docker Installation
**Purpose:** Installs and configures Docker on VM1.

**What it does:**
1. Updates package lists (`apt update`)
2. Installs Docker dependencies
3. Adds Docker's official GPG key
4. Adds Docker repository
5. Installs Docker
6. Starts Docker service
7. Enables Docker to start on boot
8. Adds user to Docker group (run Docker without sudo)

**Think of it as:** Docker setup automation

---

### **playbooks/git-python.yml** - Git & Python Installation
**Purpose:** Installs Git and Python with Flask.

**What it does:**
1. Installs Git
2. Installs Python 3
3. Installs pip (Python package manager)
4. Installs Flask and dependencies

**Think of it as:** Development tools setup

---

### **playbooks/deploy-flask.yml** - Application Deployment
**Purpose:** Deploys your Flask application.

**What it does:**
1. Clones your Git repository
2. Creates Python virtual environment
3. Installs application dependencies
4. Configures Flask app
5. Starts the application
6. Sets up systemd service (keeps app running)

**Think of it as:** Application deployment automation

---

## Quick Start Guide

### Step 1: Configure Inventory

Edit `inventory.ini` and replace with your VM1 details:

```ini
[app_servers]
vm1 ansible_host=YOUR_VM1_IP ansible_user=admin ansible_ssh_private_key_file=~/.ssh/your-key.pem
```

**Replace:**
- `YOUR_VM1_IP` - Get from Terraform output
- `your-key.pem` - Your SSH key filename

---

### Step 2: Set Up Vault Password

Create a strong password for the vault:

```bash
# Create vault password file
echo "MySecurePassword123!" > .vault_pass.txt

# Secure the file (Linux/Mac/WSL)
chmod 600 .vault_pass.txt
```

**⚠️ Important:** Choose a strong, unique password!

---

### Step 3: Create Variables Files

We'll do this step-by-step in the next section. For now, understand that we'll create:
- `group_vars/all/vars.yml` - Public settings
- `group_vars/all/vault.yml` - Encrypted secrets

---

### Step 4: Test Connection

Verify Ansible can connect to VM1:

```bash
ansible all -m ping
```

**Expected output:**
```json
vm1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

**If it fails:**
- Check VM1 is running (`terraform output`)
- Check SSH key path is correct
- Check security group allows SSH from your IP

---

### Step 5: Run Playbooks

Execute the master playbook:

```bash
# From the ansible/ directory
ansible-playbook playbooks/site.yml
```

**What happens:**
1. Ansible connects to VM1
2. Installs Docker (takes ~2-3 minutes)
3. Installs Git and Python (takes ~1 minute)
4. Deploys Flask app (takes ~1 minute)
5. Reports success/failure for each task

**Expected output:**
```
PLAY [Configure App Server] **********************

TASK [Install Docker] ****************************
changed: [vm1]

TASK [Start Docker service] **********************
ok: [vm1]

...

PLAY RECAP ***************************************
vm1 : ok=15 changed=8 unreachable=0 failed=0
```

---

## Ansible Vault Commands

### Create Encrypted File
```bash
ansible-vault create group_vars/all/vault.yml
```
- Enter vault password when prompted
- Editor opens - add your secrets
- Save and close

### Edit Encrypted File
```bash
ansible-vault edit group_vars/all/vault.yml
```
- Enter vault password
- Make changes
- Save and close

### View Encrypted File (Read-only)
```bash
ansible-vault view group_vars/all/vault.yml
```

### Change Vault Password
```bash
ansible-vault rekey group_vars/all/vault.yml
```

### Encrypt Existing File
```bash
ansible-vault encrypt group_vars/all/vault.yml
```

### Decrypt File (⚠️ Be Careful!)
```bash
ansible-vault decrypt group_vars/all/vault.yml
```
**Warning:** File will be in plain text!

---

## Running Playbooks

### Run All Playbooks (Recommended)
```bash
ansible-playbook playbooks/site.yml
```

### Run Specific Playbook
```bash
# Install Docker only
ansible-playbook playbooks/docker.yml

# Deploy Flask app only
ansible-playbook playbooks/deploy-flask.yml
```

### Dry Run (Check Mode)
```bash
# See what would change WITHOUT making changes
ansible-playbook playbooks/site.yml --check
```

### Verbose Output (For Debugging)
```bash
# Show detailed output
ansible-playbook playbooks/site.yml -v

# Even more details
ansible-playbook playbooks/site.yml -vv

# Maximum details (for troubleshooting)
ansible-playbook playbooks/site.yml -vvv
```

### Run with Different Vault Password
```bash
# Prompt for password
ansible-playbook playbooks/site.yml --ask-vault-pass

# Use different password file
ansible-playbook playbooks/site.yml --vault-password-file /path/to/password.txt
```

---

## Useful Ansible Commands

### Test Connectivity
```bash
# Ping all servers
ansible all -m ping

# Ping specific group
ansible app_servers -m ping
```

### Run Ad-Hoc Commands
```bash
# Check disk space
ansible all -m shell -a "df -h"

# Check running services
ansible all -m shell -a "systemctl status docker"

# Reboot server (⚠️ careful!)
ansible all -m reboot
```

### List Inventory
```bash
# Show all hosts
ansible-inventory --list

# Show host variables
ansible-inventory --host vm1
```

### Check Playbook Syntax
```bash
ansible-playbook playbooks/site.yml --syntax-check
```

### List Tasks in Playbook
```bash
ansible-playbook playbooks/site.yml --list-tasks
```

---

## Troubleshooting

### Error: "Could not match supplied host pattern"

**Problem:** Ansible can't find the host in inventory.

**Solution:**
1. Check `inventory.ini` has correct host name
2. Verify group names match
3. Run: `ansible-inventory --list` to see what Ansible sees

---

### Error: "Permission denied (publickey)"

**Problem:** SSH key authentication failed.

**Solution:**
1. Verify SSH key path in `inventory.ini`
2. Test SSH manually: `ssh -i ~/.ssh/key.pem admin@IP`
3. Check key permissions: `chmod 400 ~/.ssh/key.pem`
4. Verify using correct user (`admin` for Debian)

---

### Error: "Vault password was incorrect"

**Problem:** Wrong vault password.

**Solution:**
1. Check `.vault_pass.txt` has correct password
2. Try: `ansible-vault edit group_vars/all/vault.yml` to verify password
3. If forgotten, recreate vault file

---

### Error: "Failed to connect to the host via ssh"

**Problem:** Can't reach VM1.

**Solution:**
1. Check VM1 is running: `terraform output`
2. Check security group allows SSH from your IP
3. Test connection: `ansible all -m ping -vvv`
4. Verify IP in `inventory.ini` is correct

---

### Tasks Show "changed" Every Time

**Problem:** Tasks not idempotent (always show changed).

**Solution:**
- This is normal for some tasks
- Use `--check` mode to see what would change
- Review playbook tasks for proper idempotency

---

### Slow Playbook Execution

**Problem:** Playbooks take too long.

**Solution:**
1. Use `strategy: free` in playbook for parallel execution
2. Enable pipelining in `ansible.cfg`
3. Reduce fact gathering: `gather_facts: no` (if not needed)

---

## Security Best Practices

### ✅ DO

1. **Use Ansible Vault** for all secrets
2. **Add `.vault_pass.txt` to `.gitignore`**
3. **Use strong vault passwords** (16+ characters)
4. **Restrict SSH access** in security groups
5. **Keep Ansible updated:** `pip install --upgrade ansible`
6. **Use SSH keys** (never passwords)
7. **Review changes** with `--check` before applying

### ❌ DON'T

1. **Never commit `.vault_pass.txt`** to Git
2. **Never store passwords** in plain text
3. **Never use `become_password`** in plain text
4. **Never decrypt vault files** unless necessary
5. **Never run playbooks** as root without reason
6. **Never skip verification** before running in production

---

## What's Next?

After successfully setting up VM1 with Ansible:

1. **Verify Application:**
   - Access Flask app: `http://YOUR_VM1_IP:5000`
   - Check Docker containers: `docker ps`

2. **Create VM2 (Jenkins Server):**
   - Add to Terraform configuration
   - Create separate Ansible playbooks for Jenkins

3. **Set Up CI/CD Pipeline:**
   - Configure Jenkins
   - Connect to GitHub
   - Automate deployments with webhooks

---

## File Checklist

Before running playbooks, ensure you have:

- [ ] `ansible.cfg` - Created and configured
- [ ] `inventory.ini` - VM1 IP and SSH key configured
- [ ] `.vault_pass.txt` - Created with strong password
- [ ] `.gitignore` - Includes `.vault_pass.txt`
- [ ] `group_vars/all/vars.yml` - Public variables created
- [ ] `group_vars/all/vault.yml` - Secrets encrypted
- [ ] `playbooks/site.yml` - Master playbook ready
- [ ] `playbooks/docker.yml` - Docker playbook ready
- [ ] `playbooks/git-python.yml` - Git/Python playbook ready
- [ ] `playbooks/deploy-flask.yml` - Deployment playbook ready
- [ ] SSH key accessible and permissions set (400)
- [ ] VM1 running and accessible via SSH

---

## Support & Resources

### Official Documentation
- Ansible Docs: https://docs.ansible.com/
- Ansible Vault: https://docs.ansible.com/ansible/latest/user_guide/vault.html
- Ansible Modules: https://docs.ansible.com/ansible/latest/collections/index.html

### Useful Commands Reference
```bash
# Test connection
ansible all -m ping

# Run playbook
ansible-playbook playbooks/site.yml

# Dry run
ansible-playbook playbooks/site.yml --check

# Debug
ansible-playbook playbooks/site.yml -vvv

# Edit secrets
ansible-vault edit group_vars/all/vault.yml
```

---

**Last Updated:** November 2025
**Ansible Version:** ~> 2.15
**Target OS:** Debian 12 (VM1)
