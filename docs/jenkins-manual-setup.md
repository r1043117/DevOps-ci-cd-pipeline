# Jenkins Manual Setup Guide

A step-by-step guide for setting up Jenkins CI/CD server on Debian 12.

---

## Prerequisites

- Debian 12 server with SSH access
- Sudo privileges
- SSH key for connecting to your application server

---

## 1. Install Java

Jenkins requires Java 17 or higher.

```bash
sudo apt update
sudo apt install -y openjdk-17-jdk
```

Verify installation:
```bash
java -version
```

---

## 2. Install Jenkins

### Add Jenkins Repository

```bash
# Install required packages
sudo apt install -y curl gnupg

# Add Jenkins GPG key
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins repository
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update and install Jenkins
sudo apt update
sudo apt install -y jenkins
```

### Start Jenkins

```bash
sudo systemctl enable jenkins
sudo systemctl start jenkins
```

Verify Jenkins is running:
```bash
sudo systemctl status jenkins
```

---

## 3. Initial Setup

### Get Initial Admin Password

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Copy this password.

### Access Jenkins Web UI

1. Open browser: `http://YOUR_SERVER_IP:8080`
2. Paste the initial admin password
3. Click "Continue"

### Install Plugins

Select **"Install suggested plugins"** and wait for installation to complete.

Alternatively, install only these required plugins:
- git
- ssh-agent
- workflow-aggregator (Pipeline)
- pipeline-stage-view
- ssh-credentials
- credentials

### Create Admin User

Fill in the form:
- Username: `admin`
- Password: (choose a strong password)
- Full name: `Administrator`
- Email: `admin@example.com`

Click "Save and Continue"

### Configure Jenkins URL

Keep the default URL or set your domain. Click "Save and Finish".

Click "Start using Jenkins"

---

## 4. Add SSH Credentials

SSH credentials allow Jenkins to connect to your application server for deployments.

### Navigate to Credentials

1. Go to: **Manage Jenkins** → **Credentials**
2. Click on **(global)** under "Stores scoped to Jenkins"
3. Click **"Add Credentials"**

### Add SSH Key

Fill in:
- **Kind**: SSH Username with private key
- **Scope**: Global
- **ID**: `vm1-ssh-key` (or any memorable name)
- **Description**: SSH key for App Server
- **Username**: `admin` (the user on your app server)
- **Private Key**: Select "Enter directly"
  - Click "Add"
  - Paste your private key content (the entire content of your .pem file)

Click **"Create"**

---

## 5. Create Pipeline Job

### Create New Item

1. From Jenkins dashboard, click **"New Item"**
2. Enter name: `flask-deploy`
3. Select **"Pipeline"**
4. Click **"OK"**

### Configure Pipeline

Scroll down to **Pipeline** section:

1. **Definition**: Pipeline script from SCM
2. **SCM**: Git
3. **Repository URL**: `https://github.com/YOUR_USERNAME/YOUR_REPO.git`
4. **Branch Specifier**: `*/main`
5. **Script Path**: `Jenkinsfile`

Click **"Save"**

---

## 6. Create Jenkinsfile

Create a `Jenkinsfile` in your repository root:

```groovy
pipeline {
    agent any

    environment {
        APP_SERVER = 'YOUR_APP_SERVER_IP'
        APP_USER = 'admin'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Deploy') {
            steps {
                sshagent(['vm1-ssh-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${APP_USER}@${APP_SERVER} << 'EOF'
                            cd /var/www/flask-app
                            git pull origin main
                            source venv/bin/activate
                            pip install -r requirements.txt
                            sudo systemctl restart flask-app
                        EOF
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
```

Replace:
- `YOUR_APP_SERVER_IP` with your application server's IP address
- Adjust the deployment commands to match your application

---

## 7. Run Your First Build

1. Go to your pipeline job (`flask-deploy`)
2. Click **"Build Now"**
3. Click on the build number to see progress
4. Click **"Console Output"** to see detailed logs

---

## Troubleshooting

### Jenkins won't start
```bash
# Check logs
sudo journalctl -u jenkins -f

# Check if port 8080 is in use
sudo netstat -tlnp | grep 8080
```

### Can't connect to app server
```bash
# Test SSH connection manually from Jenkins server
sudo -u jenkins ssh -i /path/to/key admin@APP_SERVER_IP
```

### Plugin installation failed
1. Go to **Manage Jenkins** → **Manage Plugins**
2. Check the **Available** tab
3. Search and install missing plugins manually

### Permission denied errors
```bash
# Ensure Jenkins user owns its directories
sudo chown -R jenkins:jenkins /var/lib/jenkins
```

---

## Security Recommendations

1. **Change default port**: Edit `/etc/default/jenkins` to use a different port
2. **Enable HTTPS**: Use a reverse proxy (nginx) with SSL certificate
3. **Restrict access**: Configure Matrix-based security in Manage Jenkins → Security
4. **Regular updates**: Keep Jenkins and plugins updated
5. **Backup**: Regularly backup `/var/lib/jenkins` directory

---

## Quick Reference

| Item | Location/Command |
|------|------------------|
| Jenkins URL | `http://SERVER_IP:8080` |
| Config directory | `/var/lib/jenkins` |
| Logs | `sudo journalctl -u jenkins` |
| Restart Jenkins | `sudo systemctl restart jenkins` |
| Initial password | `/var/lib/jenkins/secrets/initialAdminPassword` |

---

## Summary

1. Install Java and Jenkins
2. Complete initial setup wizard
3. Create admin user
4. Add SSH credentials for deployment
5. Create pipeline job pointing to your Git repository
6. Add Jenkinsfile to your repository
7. Run build and verify deployment
