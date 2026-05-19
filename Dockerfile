FROM python:3.9-slim

# Installare dipendenze di sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    netcat-openbsd=1.229-1 \
    && rm -rf /var/lib/apt/lists/*

# Settare directory di lavoro
WORKDIR /app

# Copiare il progetto
COPY . /app/

# Installare automx2 e dipendenze
RUN pip install --no-cache-dir automx2==2026.2 PyMySQL==1.1.0

# Variabili d'ambiente di default per MariaDB
ENV MYSQL_HOST=mariadb \
    MYSQL_PORT=3306 \
    MYSQL_USER=automx2 \
    MYSQL_PASSWORD=automx2_password \
    MYSQL_DATABASE=automx2 \
    MYSQL_CHARSET=utf8mb4

# Variabili d'ambiente per l'applicazione
ENV APP_HOST=0.0.0.0 \
    APP_PORT=4243 \
    LOG_LEVEL=DEBUG \
    AUTOMX2_CONF=/app/automx2.conf

# Creare directory per configurazione e log e rendere script eseguibile
RUN mkdir -p /app/config /app/logs && \
    chmod +x /app/entrypoint.sh

# Esporre la porta
EXPOSE 4243

# Entry point: esegui lo script di inizializzazione
ENTRYPOINT ["/app/entrypoint.sh"]
