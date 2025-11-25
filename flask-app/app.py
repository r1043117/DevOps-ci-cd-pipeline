"""
Simple Flask Application
=========================
A minimal Flask app that returns a greeting message.
This app is designed for deployment to VM1 via Ansible automation.
"""

from flask import Flask

app = Flask(__name__)


@app.route('/')
def hello():
    """
    Root endpoint - returns a simple greeting message.
    """
    return 'Hello from Flask on VM1!'


@app.route('/health')
def health():
    """
    Health check endpoint - useful for monitoring and load balancers.
    """
    return {'status': 'healthy', 'message': 'Flask app is running'}


if __name__ == '__main__':
    # Run the app on all interfaces (0.0.0.0) so it's accessible externally
    # Port 5000 is the default Flask port
    app.run(host='0.0.0.0', port=5000, debug=False)
