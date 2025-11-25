# Flask App Deployment Guide

## Quick Start

Deploy everything with one command:

```bash
cd ansible/
ansible-playbook playbooks/site.yml
```

This will:
1. Install Docker on VM1 (~ 3 minutes)
2. Install Python tools (~ 1 minute)
3. Deploy Flask app in Docker (~ 2 minutes)

After completion, access your app at:
- **Main app**: http://54.171.192.121:5000/
- **Health check**: http://54.171.192.121:5000/health

---

## Individual Playbooks

Run specific steps only:

### Install Docker Only
```bash
ansible-playbook playbooks/docker.yml
```

### Deploy Flask App Only
```bash
ansible-playbook playbooks/deploy-flask.yml
```

### Full Deployment
```bash
ansible-playbook playbooks/site.yml
```

---

## Redeployment (After Code Changes)

When you update Flask code:

```bash
# Fast: Just redeploy the app
ansible-playbook playbooks/deploy-flask.yml
```

This will:
- Copy new files to VM1
- Rebuild Docker image
- Stop old container
- Start new container with updated code

---

## Troubleshooting

### Check if app is running
```bash
ssh -i ~/.ssh/klinkr-key.pem admin@54.171.192.121
docker ps
docker logs flask-app
```

### Stop the app
```bash
docker stop flask-app
docker rm flask-app
```

### Rebuild from scratch
```bash
# On VM1:
docker stop flask-app
docker rm flask-app
docker rmi flask-app:latest

# Then run deployment again
ansible-playbook playbooks/deploy-flask.yml
```

### Cannot connect to VM1
- Check VM1 is running (AWS console)
- Check security group allows SSH from your IP
- Test: `ansible vm1 -m ping`

### Port 5000 not accessible
- Check security group allows port 5000
- Run: `terraform output` to see security group rules

---

## What Gets Deployed

### On VM1:
- Docker CE installed
- Flask app files in `/opt/flask-app/`
- Docker container named `flask-app` running on port 5000
- Auto-restart enabled (survives reboots)

### Docker Container:
- Image: `flask-app:latest`
- Base: `python:3.11-slim`
- WSGI server: Gunicorn with 4 workers
- Port: 5000
- Restart policy: `unless-stopped`

---

## Useful Commands

### Check deployment status
```bash
ansible vm1 -m shell -a "docker ps"
ansible vm1 -m shell -a "docker logs flask-app --tail 20"
```

### Test the app
```bash
curl http://54.171.192.121:5000/
curl http://54.171.192.121:5000/health
```

### View all running containers
```bash
ansible vm1 -m shell -a "docker ps -a"
```

---

## Files Created by Deployment

```
VM1:/opt/flask-app/
├── app.py              # Flask application
├── requirements.txt    # Python dependencies
└── Dockerfile          # Docker build instructions
```

---

## Next Steps

1. ✅ Deploy Flask app to VM1
2. ⏳ Add VM2 (Jenkins server) to Terraform
3. ⏳ Set up Jenkins CI/CD pipeline
4. ⏳ Configure GitHub webhooks
5. ⏳ Auto-deploy on git push
