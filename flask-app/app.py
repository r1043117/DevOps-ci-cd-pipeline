"""
Simple Flask Application
=========================
A Flask app with HTML/CSS templates for easy webpage updates.
Deployed to VM1 via Jenkins CI/CD pipeline.
"""

from flask import Flask, render_template

app = Flask(__name__)

# ===========================================
# EDIT THESE VALUES TO UPDATE YOUR WEBPAGE
# ===========================================
SITE_TITLE = "My DevOps Project"
WELCOME_MESSAGE = "This Flask app is deployed automatically via Jenkins CI/CD!"
ENVIRONMENT = "Productions"
VERSION = "1.4.0"
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


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
