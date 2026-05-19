# Automx2 Docker Setup

## Quick Start

### Con Docker Compose (consigliato)

```bash
# Copia il file di configurazione
cp .env.example .env

# Modifica le variabili d'ambiente necessarie in .env (se necessario)

# Avvia i container
docker-compose up -d

# Visualizza i log
docker-compose logs -f automx2

# Inizializza il database (eseguire una volta)
docker-compose exec automx2 curl -X POST http://localhost:4243/initdb/
```

### Con Docker manuale

```bash
# Build dell'immagine
docker build -t automx2:latest .

# Esecuzione con variabili d'ambiente
docker run -d \
  --name automx2 \
  -e MYSQL_HOST=mariadb_host \
  -e MYSQL_PORT=3306 \
  -e MYSQL_USER=automx2 \
  -e MYSQL_PASSWORD=tuapassword \
  -e MYSQL_DATABASE=automx2 \
  -e APP_HOST=0.0.0.0 \
  -e APP_PORT=4243 \
  -e LOG_LEVEL=DEBUG \
  -p 4243:4243 \
  automx2:latest
```

## Variabili d'Ambiente

### Configurazione MariaDB
- `MYSQL_HOST`: Host del server MariaDB (default: mariadb)
- `MYSQL_PORT`: Porta del server MariaDB (default: 3306)
- `MYSQL_USER`: Username per MariaDB (default: automx2)
- `MYSQL_PASSWORD`: Password per MariaDB (default: automx2_password)
- `MYSQL_DATABASE`: Nome del database (default: automx2)
- `MYSQL_CHARSET`: Charset per il database (default: utf8mb4)

### Configurazione Applicazione
- `APP_HOST`: Host dove bindare l'app (default: 0.0.0.0)
- `APP_PORT`: Porta dell'applicazione (default: 4243)
- `LOG_LEVEL`: Livello di log (default: DEBUG, oppure INFO, WARNING, ERROR)
- `AUTOMX2_CONF`: Path al file di configurazione (default: /app/automx2.conf)

## Comandi Utili

```bash
# Visualizzare log
docker-compose logs -f automx2

# Fermare i container
docker-compose down

# Fermare e rimuovere i volumi
docker-compose down -v

# Accedere al container
docker-compose exec automx2 bash

# Accedere al database MariaDB
docker-compose exec mariadb mysql -u automx2 -p -D automx2

# Inizializzare il database con dati di esempio
docker-compose exec automx2 curl -X POST http://localhost:4243/initdb/

# Inizializzare il database con seed data da JSON
docker-compose exec -T automx2 curl -X POST --json @seed-data.json http://localhost:4243/initdb/

# Testare la configurazione
docker-compose exec automx2 curl http://localhost:4243/mail/config-v1.1.xml?emailaddress=user@example.com
```

## Configurazione Persistente

I volumi Docker permettono di mantenere i dati:
- `mariadb_data`: Dati del database MariaDB
- `./config`: Configurazioni dell'applicazione
- `./logs`: Log dell'applicazione
- `./automx2.conf`: File di configurazione runtime

## Architettura

```
┌─────────────────────────────┐
│     Mail Client             │
│  (Thunderbird, Outlook)     │
└──────────────┬──────────────┘
               │ HTTPS/HTTP
        ┌──────▼──────┐
        │   NGINX/    │
        │   Apache    │
        └──────┬──────┘
               │
        ┌──────▼──────────┐
        │  automx2:4243   │
        │    (Flask)      │
        └──────┬──────────┘
               │
        ┌──────▼──────────┐
        │  MariaDB:3306   │
        │  (Database)     │
        └─────────────────┘
```

## Note di Produzione

Per un ambiente di produzione:
1. Usa HTTPS invece di HTTP
2. Configura un web server (NGINX/Apache) come proxy
3. Imposta `LOG_LEVEL=WARNING` o superiore
4. Usa password forti per il database
5. Abilita il proxy_count se dietro un reverse proxy
6. Considera l'uso di volumi persistenti per i dati

Consulta la documentazione ufficiale: https://rseichter.github.io/automx2/

