# GitHub Actions CI/CD Pipeline

Questa repository usa GitHub Actions per automatizzare il build e il push dell'immagine Docker.

## Workflow

### 1. Docker Build and Push (`docker-build-push.yml`)

**Trigger:**
- Push su `main` e `develop`
- Push di tag `v*` (versioni semantiche)
- Pull requests
- Manuale (workflow_dispatch)

**Azioni:**
- ✅ Build dell'immagine Docker
- ✅ Push su GitHub Container Registry (ghcr.io)
- ✅ Tagging automatico:
  - `main` → `latest`
  - `develop` → `develop`
  - `v1.2.3` → `1.2.3`, `1.2`, `latest`
  - Commit SHA per tracciabilità
- ✅ Cache layer per velocizzare i build successivi

### 2. Test Docker (`test-docker.yml`)

**Trigger:**
- Pull requests su `main` e `develop`
- Push su `main`

**Azioni:**
- ✅ Build dell'immagine in test mode
- ✅ Startup container con MariaDB
- ✅ Health check
- ✅ Test degli endpoint:
  - `/` (health check)
  - `/initdb/` (inizializzazione database)
  - `/mail/config-v1.1.xml` (autoconfig endpoint)
- ✅ Cleanup automatico

## Come usare

### Build automatico su push

```bash
# Push su main - builda e pubblica come 'latest'
git push origin main

# Push su develop - builda e pubblica come 'develop'
git push origin develop

# Push di tag versione - builda e pubblica versione semantica
git tag v1.0.0
git push origin v1.0.0
```

### Build manuale

Nel tab "Actions" della repository, cliccare su "Build and Push Docker Image" → "Run workflow"

### Usare l'immagine da GitHub Container Registry

```bash
docker pull ghcr.io/yourusername/automx2:latest
docker pull ghcr.io/yourusername/automx2:main
docker pull ghcr.io/yourusername/automx2:v1.0.0

# Con docker-compose
docker-compose pull automx2
```

## Permessi richiesti

La repository ha bisogno dei seguenti permessi:
- `contents: read` - Legge il codice
- `packages: write` - Pubblica pacchetti su GHCR

Questi sono configurati automaticamente nelle Actions.

## Variabili d'ambiente nel workflow

| Variabile | Valore | Descrizione |
|-----------|--------|-------------|
| `REGISTRY` | `ghcr.io` | Registro Container per GitHub |
| `IMAGE_NAME` | `${{ github.repository }}` | Nome della repository (owner/name) |

## Tag Docker automatici

### Per branch push

| Branch | Tag |
|--------|-----|
| `main` | `main`, `latest` |
| `develop` | `develop` |
| `feature/xyz` | `feature-xyz` |

### Per tag release

| Tag | Docker Tags |
|-----|-------------|
| `v1.2.3` | `1.2.3`, `1.2`, `latest` |
| `v2.0.0` | `2.0.0`, `2.0`, `latest` |

### Per commit

Tutti i build includono il tag `sha-<commit-short>` per tracciabilità

## Troubleshooting

### Build fallisce su PR

Il workflow di test fallisce se:
- Il Dockerfile ha sintassi errata
- Il container non si avvia
- Gli endpoint non rispondono
- Il database non si connette

Controllare i log di GitHub Actions nel tab "Actions" della PR.

### Container non si pubblica

Se `docker-build-push` non pubblica l'immagine:
- Verificare di essere loggati su ghcr.io
- Controllare i permessi del token `GITHUB_TOKEN`
- Verificare che il branch sia `main` o che il tag sia `v*`

### Accesso a immagini private

Per usare immagini private da GitHub:

```bash
docker login ghcr.io -u USERNAME -p TOKEN
docker pull ghcr.io/username/automx2:latest
```

Dove `TOKEN` è un Personal Access Token con scope `read:packages`.

## Riferimenti

- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Docker GitHub Actions](https://github.com/docker/build-push-action)
- [Semantic Versioning](https://semver.org/)
