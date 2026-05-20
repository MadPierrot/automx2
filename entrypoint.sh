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

# ──────────────────────────────────────────────
# Gestione graceful shutdown (SIGTERM da K8s)
# ──────────────────────────────────────────────

FLASK_PID=""

graceful_shutdown() {
  echo "[entrypoint] SIGTERM ricevuto - avvio graceful shutdown..."

  if [ -n "$FLASK_PID" ] && kill -0 "$FLASK_PID" 2>/dev/null; then
    echo "[entrypoint] Invio SIGTERM a Flask (PID: $FLASK_PID)..."
    kill -SIGTERM "$FLASK_PID"

    # Attendi fino a 30s che Flask termini
    WAIT=0
    while kill -0 "$FLASK_PID" 2>/dev/null; do
      if [ $WAIT -ge 30 ]; then
        echo "[entrypoint] Timeout raggiunto - invio SIGKILL a Flask..."
        kill -SIGKILL "$FLASK_PID"
        break
      fi
      sleep 1
      WAIT=$((WAIT + 1))
    done

    echo "[entrypoint] Flask terminato."
  fi

  echo "[entrypoint] Shutdown completato."
  exit 0
}

# Registra il trap per SIGTERM e SIGINT
trap graceful_shutdown SIGTERM SIGINT

# ──────────────────────────────────────────────
# Avvia Flask in background e salva il PID
# ──────────────────────────────────────────────
echo "[entrypoint] Avvio Flask..."
flask run --host=${APP_HOST} --port=${APP_PORT} &
FLASK_PID=$!
echo "[entrypoint] Flask avviato con PID: $FLASK_PID"

# Attendi il processo Flask (il wait è interrompibile dai trap)
wait "$FLASK_PID"
EXIT_CODE=$?

echo "[entrypoint] Flask uscito con codice: $EXIT_CODE"
exit $EXIT_CODE
