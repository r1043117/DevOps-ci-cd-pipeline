# Multi-stage build for Flask application
# Stage 1: Build stage
FROM python:3.11-slim as builder

# Set working directory
WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --user -r requirements.txt


# Stage 2: Runtime stage
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Create non-root user for security
RUN useradd -m -u 1000 flaskuser && \
    chown -R flaskuser:flaskuser /app

# Copy Python dependencies from builder
COPY --from=builder --chown=flaskuser:flaskuser /root/.local /home/flaskuser/.local

# Copy application code and templates
COPY --chown=flaskuser:flaskuser app.py .
COPY --chown=flaskuser:flaskuser templates/ templates/
COPY --chown=flaskuser:flaskuser static/ static/

# Update PATH to include user site-packages
ENV PATH=/home/flaskuser/.local/bin:$PATH

# Switch to non-root user
USER flaskuser

# Expose Flask port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:80/health')" || exit 1

# Run gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:80", "--workers", "4", "--timeout", "120", "--access-logfile", "-", "--error-logfile", "-", "app:app"]
