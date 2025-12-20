# FLASK APPLICATIE
# Een simpele web applicatie die draait in een Docker container.

from flask import Flask, render_template, jsonify
import os
from datetime import datetime

app = Flask(__name__)

# =============================================================================
# TEAM VERIFICATIE (alleen actief in staging)
# =============================================================================
# Deze check zorgt ervoor dat alle teamleden vermeld staan voordat
# de applicatie naar productie mag. Voeg je naam toe aan de lijst!
# =============================================================================
TEAM_MEMBERS = [
    "Thijs",
    # "Yannick",  # <-- Uncomment deze regel om staging te laten slagen!
]

def verify_team_for_staging():
    """Controleer of alle vereiste teamleden aanwezig zijn (alleen in staging)."""
    hostname = os.uname().nodename
    is_staging = "staging" in hostname.lower()

    if is_staging:
        required_members = ["Yannick"]
        missing = [m for m in required_members if m not in TEAM_MEMBERS]
        if missing:
            return False, f"Staging GEFAALD: Teamlid(leden) ontbreken: {', '.join(missing)}"

    return True, "OK"


# Hoofdpagina
@app.route('/')
def home():
    return render_template('index.html',
                           hostname=os.uname().nodename,
                           timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


# Health check endpoint (voor Jenkins pipeline)
@app.route('/health')
def health():
    # Voer team verificatie uit (faalt alleen in staging als Yannick ontbreekt)
    team_ok, message = verify_team_for_staging()

    if not team_ok:
        return jsonify({
            "status": "unhealthy",
            "error": message,
            "timestamp": datetime.now().isoformat(),
            "hostname": os.uname().nodename
        }), 500

    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "hostname": os.uname().nodename
    })


# API info endpoint
@app.route('/api/info')
def api_info():
    return jsonify({
        "app": "Flask CI/CD Demo",
        "version": "1.0.0",
        "environment": os.getenv("ENVIRONMENT", "production"),
        "hostname": os.uname().nodename
    })


if __name__ == '__main__':
    # Draai op poort 80 (standaard HTTP poort)
    app.run(host='0.0.0.0', port=80, debug=False)
