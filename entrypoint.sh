#!/bin/bash
# Script di inizializzazione per automx2
# Genera la configurazione da variabili d'ambiente

set -e

# Valori di default
MYSQL_HOST=${MYSQL_HOST:-mariadb}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_USER=${MYSQL_USER:-automx2}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-automx2_password}
MYSQL_DATABASE=${MYSQL_DATABASE:-automx2}
MYSQL_CHARSET=${MYSQL_CHARSET:-utf8mb4}
LOG_LEVEL=${LOG_LEVEL:-DEBUG}
APP_HOST=${APP_HOST:-0.0.0.0}
APP_PORT=${APP_PORT:-4243}

# Genera il file di configurazione
cat > /app/automx2.conf <<EOF
[automx2]
# Log level: DEBUG, INFO, WARNING, ERROR
loglevel = ${LOG_LEVEL}

# Echo SQL commands into log? Used for debugging.
db_echo = no

# Database URI - MariaDB configuration
db_uri = mysql+pymysql://${MYSQL_USER}:${MYSQL_PASSWORD}@${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DATABASE}?charset=${MYSQL_CHARSET}

# Number of proxy servers between automx2 and the client (default: 0).
proxy_count = 1
EOF

echo "Configuration file generated at /app/automx2.conf"

# Attesa del database MariaDB
echo "Waiting for MariaDB at ${MYSQL_HOST}:${MYSQL_PORT}..."
until nc -z ${MYSQL_HOST} ${MYSQL_PORT}; do
  echo "MariaDB is unavailable - sleeping"
  sleep 2
done
echo "MariaDB is up - continuing"

# Esporta la variabile per Flask
export FLASK_APP=automx2.server:app
export AUTOMX2_CONF=/app/automx2.conf
export FLASK_ENV=production

# Inizializza il database
echo "Initializing database..."
python3 << 'PYEOF'
import sys
from automx2.server import app
from automx2.model import Base
from automx2.model import db
with app.app_context():
    Base.metadata.create_all(db.engine)
    print("Database initialized successfully")
PYEOF

# Avvia Flask
exec flask run --host=${APP_HOST} --port=${APP_PORT}
