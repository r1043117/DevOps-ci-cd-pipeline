# Simple Flask Application

A minimal Flask web application for deployment to AWS EC2 via Ansible automation.

## What This App Does

- **Root endpoint** (`/`): Returns a simple greeting message
- **Health check** (`/health`): Returns JSON status for monitoring

## Local Development

### Prerequisites
- Python 3.11+
- pip3

### Setup and Run

1. Create a virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate
Install dependencies:
pip3 install -r requirements.txt
Run the application:
python3 app.py
Test it:
curl http://localhost:5000/
curl http://localhost:5000/health
Deployment
This app is designed to be deployed to VM1 (52.213.207.167) using Ansible. The deployment playbook will:
Clone this repository to the server
Set up a Python virtual environment
Install dependencies
Run the Flask app as a systemd service
Project Structure
flask-app/
├── app.py              # Main Flask application
├── requirements.txt    # Python dependencies
├── .gitignore         # Git exclusions
└── README.md          # This file
Next Steps
Push this code to a GitHub repository
Create an Ansible deployment playbook (deploy-flask.yml)
Deploy to VM1
Configure as a systemd service to keep it running EOF
Initialize git
git init git add . git status
