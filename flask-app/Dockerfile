# DOCKERFILE VOOR FLASK APPLICATIE
# Dit bestand beschrijft hoe de Docker container gebouwd wordt.

# Basis image: Python 3.11 op Debian (slim variant voor kleinere image)
FROM python:3.11-slim

# Werkdirectory in de container
WORKDIR /app

# Kopieer eerst requirements (voor betere Docker cache)
COPY requirements.txt .

# Installeer Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Kopieer de rest van de applicatie
COPY . .

# Poort 80 beschikbaar maken
EXPOSE 80

# Start de applicatie met Gunicorn (production-ready server)
CMD ["gunicorn", "--bind", "0.0.0.0:80", "app:app"]
