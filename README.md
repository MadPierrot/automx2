# automx2 - Docker Container

![Build and Push Docker Image](https://github.com/yourusername/automx2/actions/workflows/docker-build-push.yml/badge.svg)
![Test Docker Image](https://github.com/yourusername/automx2/actions/workflows/test-docker.yml/badge.svg)

Containerizzazione di [automx2](https://rseichter.github.io/automx2/) - Email client configuration made easy.

## Cos'è automx2?

automx2 è un servizio web che fornisce configurazione automatica per client email (Thunderbird, Outlook, Evolution, ecc.) tramite i protocolli:
- **Autoconfig** (Mozilla)
- **Autodiscover** (Microsoft)
- **Mobileconfig** (Apple)
- **DNS SRV records** (RFC standard)

## Quick Start

### Con Docker Compose

```bash
# Clona la repository
git clone https://github.com/yourusername/automx2.git
cd automx2

# Copia il file di configurazione
cp .env.example .env

# Avvia i container
docker-compose up -d

# Visualizza i log
docker-compose logs -f automx2

# Inizializza il database
docker-compose exec automx2 curl -X POST http://localhost:4243/initdb/
```

### Con Docker Run

```bash
docker run -d \
  --name automx2 \
  -e MYSQL_HOST=localhost \
  -e MYSQL_USER=automx2 \
  -e MYSQL_PASSWORD=password \
  -e MYSQL_DATABASE=automx2 \
  -p 4243:4243 \
  ghcr.io/yourusername/automx2:latest
```

### Con Docker Compose - Produzione

```yaml
version: '3.8'
services:
  mariadb:
    image: mariadb:11.0
    environment:
      MARIADB_ROOT_PASSWORD: root_password
      MARIADB_DATABASE: automx2
      MARIADB_USER: automx2
      MARIADB_PASSWORD: secure_password
    volumes:
      - mariadb_data:/var/lib/mysql

  automx2:
    image: ghcr.io/yourusername/automx2:latest
    environment:
      MYSQL_HOST: mariadb
      MYSQL_USER: automx2
      MYSQL_PASSWORD: secure_password
      MYSQL_DATABASE: automx2
      LOG_LEVEL: WARNING
    ports:
      - "4243:4243"
    depends_on:
      - mariadb

volumes:
  mariadb_data:
```

## Variabili d'Ambiente

| Variabile | Default | Descrizione |
|-----------|---------|-------------|
| `MYSQL_HOST` | `mariadb` | Host del database MariaDB |
| `MYSQL_PORT` | `3306` | Porta del database |
| `MYSQL_USER` | `automx2` | Username del database |
| `MYSQL_PASSWORD` | `automx2_password` | Password del database |
| `MYSQL_DATABASE` | `automx2` | Nome del database |
| `MYSQL_CHARSET` | `utf8mb4` | Charset del database |
| `APP_HOST` | `0.0.0.0` | Host dove bindare l'app |
| `APP_PORT` | `4243` | Porta dell'applicazione |
| `LOG_LEVEL` | `DEBUG` | Livello di log (DEBUG, INFO, WARNING, ERROR) |

## Comandi Utili

```bash
# Visualizzare i log
docker-compose logs -f automx2

# Accedere al container
docker-compose exec automx2 bash

# Accedere al database
docker-compose exec mariadb mysql -u automx2 -p -D automx2

# Fermare i container
docker-compose down

# Fermare e rimuovere i volumi
docker-compose down -v

# Test di configurazione
curl 'http://localhost:4243/mail/config-v1.1.xml?emailaddress=user@example.com'

# Autodiscover test
curl -X POST 'http://localhost:4243/autodiscover/autodiscover.xml' \
  -H 'Content-Type: application/xml' \
  -d '<Autodiscover><Request><EMailAddress>user@example.com</EMailAddress></Request></Autodiscover>'
```

## Architettura

```
┌─────────────────────────────────────────────┐
│         Mail Client (Thunderbird/Outlook)   │
└────────────────────┬────────────────────────┘
                     │ HTTPS/HTTP
        ┌────────────▼──────────┐
        │  NGINX/Apache Proxy   │  (opzionale, consigliato)
        └────────────┬──────────┘
                     │
        ┌────────────▼──────────────┐
        │  automx2 (Flask)          │
        │  port 4243                │
        └────────────┬──────────────┘
                     │
        ┌────────────▼──────────────┐
        │  MariaDB Database         │
        │  port 3306                │
        └───────────────────────────┘
```

## CI/CD Pipeline

Il progetto usa GitHub Actions per:

1. **Test automatico** su ogni pull request
   - Build dell'immagine
   - Test di startup
   - Test degli endpoint
   - Controllo di sicurezza

2. **Build e Push** su GitHub Container Registry
   - Su push a `main` → `latest`
   - Su push a `develop` → `develop`
   - Su tag `v*` → versione semantica

3. **Linting e Security**
   - Dockerfile linting
   - Vulnerability scanning (Trivy)
   - Python linting

Vedi [.github/WORKFLOW.md](.github/WORKFLOW.md) per i dettagli.

## Versioning

La repository usa **Semantic Versioning**:

```bash
# Build di sviluppo
git push origin develop

# Build di produzione
git tag v1.0.0
git push origin v1.0.0
```

I tag Docker seguiranno automaticamente il versioning.

## Immagini disponibili

- `ghcr.io/yourusername/automx2:latest` - ultima versione di main
- `ghcr.io/yourusername/automx2:main` - branch main
- `ghcr.io/yourusername/automx2:develop` - branch develop
- `ghcr.io/yourusername/automx2:v1.2.3` - versione specifica
- `ghcr.io/yourusername/automx2:sha-abc1234` - build specifico

## Configurazione per Produzione

### 1. Configura un reverse proxy (NGINX)

```nginx
server {
    listen 80;
    listen 443 ssl http2;
    server_name autoconfig.example.com;

    ssl_certificate /etc/letsencrypt/live/autoconfig.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/autoconfig.example.com/privkey.pem;

    location / {
        proxy_pass http://automx2:4243/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /initdb {
        allow 127.0.0.1;
        deny all;
        proxy_pass http://automx2:4243/initdb;
    }
}
```

### 2. Usa password forti

```bash
# Genera una password casuale
openssl rand -base64 32
```

### 3. Imposta LOG_LEVEL appropriato

```bash
# Produzione
LOG_LEVEL=WARNING

# Debug
LOG_LEVEL=DEBUG
```

### 4. Backup dei dati

```bash
# Backup del database
docker-compose exec mariadb mysqldump -u automx2 -p automx2 > backup.sql

# Restore dal backup
docker-compose exec -T mariadb mysql -u automx2 -p automx2 < backup.sql
```

## Troubleshooting

### Container non si avvia

```bash
# Visualizza i log
docker-compose logs automx2

# Verifica la connessione al database
docker-compose exec automx2 nc -zv mariadb 3306
```

### Database non accessibile

```bash
# Controlla lo stato di MariaDB
docker-compose logs mariadb

# Riavvia MariaDB
docker-compose restart mariadb
```

### Immagine non si builda

```bash
# Pulisci il cache di build
docker-compose build --no-cache automx2

# Verifica il Dockerfile
docker build -f Dockerfile .
```

## Documentazione

- [automx2 Official](https://rseichter.github.io/automx2/)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [CI/CD Workflow](.github/WORKFLOW.md)

## License

automx2 è sotto licenza GNU General Public License v3 o successiva.
Vedi la [licenza ufficiale](https://github.com/rseichter/automx2/blob/master/LICENSE) per i dettagli.

## Support

- 🐛 [Issue Tracker](https://github.com/yourusername/automx2/issues)
- 💬 [Discussions](https://github.com/yourusername/automx2/discussions)
- 📧 [automx2 Author](https://rseichter.github.io/automx2/#_contact)

## Changelog

Vedi [CHANGELOG.md](CHANGELOG.md) per la storia delle versioni.
