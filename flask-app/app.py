"""
Simple Flask Application
=========================
A Flask app with HTML/CSS templates for easy webpage updates.
Deployed to VM1 via Jenkins CI/CD pipeline.
"""

from flask import Flask, render_template, jsonify
import requests
import os

app = Flask(__name__)

# ===========================================
# JENKINS CONFIGURATION
# ===========================================
JENKINS_URL = os.environ.get('JENKINS_URL', 'http://52.48.160.46:8080')
JENKINS_USER = os.environ.get('JENKINS_USER', 'admin')
JENKINS_TOKEN = os.environ.get('JENKINS_TOKEN', '')  # Set via environment variable
JOB_NAME = os.environ.get('JENKINS_JOB', 'flask-app')

# ===========================================
# EDIT THESE VALUES TO UPDATE YOUR WEBPAGE
# ===========================================
SITE_TITLE = "My DevOps Project"
WELCOME_MESSAGE = "This Flask app is deployed automatically via Jenkins CI/CD!"
ENVIRONMENT = "Productions"
VERSION = "1.5.0"
# ===========================================


@app.route('/')
def home():
    """
    Home page - renders the HTML template with your content.
    Edit the variables above to change what's displayed!
    """
    return render_template('index.html',
                           title=SITE_TITLE,
                           message=WELCOME_MESSAGE,
                           environment=ENVIRONMENT,
                           version=VERSION)


@app.route('/health')
def health():
    """
    Health check endpoint - used by Docker and load balancers.
    """
    return {'status': 'healthy', 'message': 'Flask app is running'}


@app.route('/api/pipeline')
def pipeline_status():
    """
    Fetch Jenkins pipeline status for the last build.
    Returns stage information with status for visualization.
    """
    if not JENKINS_TOKEN:
        return jsonify({
            'error': 'Jenkins token not configured',
            'stages': [],
            'build_number': None,
            'result': 'UNKNOWN'
        })

    try:
        build_url = f"{JENKINS_URL}/job/{JOB_NAME}/lastBuild/wfapi/describe"
        auth = (JENKINS_USER, JENKINS_TOKEN)
        response = requests.get(build_url, auth=auth, timeout=5)

        if response.status_code == 200:
            data = response.json()
            stages = []
            for stage in data.get('stages', []):
                stages.append({
                    'name': stage.get('name'),
                    'status': stage.get('status'),
                    'duration': stage.get('durationMillis', 0) // 1000
                })

            return jsonify({
                'build_number': data.get('id'),
                'result': data.get('status'),
                'stages': stages,
                'duration': data.get('durationMillis', 0) // 1000
            })
        else:
            return jsonify({
                'error': f'Jenkins returned {response.status_code}',
                'stages': [],
                'build_number': None,
                'result': 'UNKNOWN'
            })
    except requests.exceptions.RequestException as e:
        return jsonify({
            'error': str(e),
            'stages': [],
            'build_number': None,
            'result': 'UNREACHABLE'
        })


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
