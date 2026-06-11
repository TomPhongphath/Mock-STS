# Plan: Restructure by Layer (Diagram STS v2.0)

## Decisions
- ✅ เพิ่ม BFF Web + BFF Mobile
- ✅ เพิ่ม Database กลับมา
- ✅ แยก branch ตาม layer

---

## Phase 1: Database Layer → `db` Branch

### Restore PostgreSQL (UAT + Master)
- `postgres_uat`: image postgres:17-alpine, port 5433, bind mount `data/pgdata_uat`
- `postgres_master`: image postgres:17-alpine, port 5432, bind mount `data/pgdata_master`
- Healthchecks, env vars (`POSTGRES_PASSWORD` from .env)

### Restore pgAdmin
- port 5050, servers.json, pgpass
- `PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED: "False"`

### Restore PostgreSQL Exporters
- `postgres-exporter-master` + `postgres-exporter-uat` (Prometheus)

### Restore Backup
- `backup/` scripts (db-backup.sh, db-restore.sh, check-backup.sh)
- Backup container in compose

### Headscale → SQLite (keep as-is, DB layer is just PostgreSQL)

### Files owned by `db` branch
| File | Description |
|------|-------------|
| `pgadmin/servers.json` | pgAdmin auto-connect config |
| `pgadmin/pgpass` | Password file for auto-connect |
| `backup/db-backup.sh` | Database backup script |
| `backup/db-restore.sh` | Database restore script |
| `backup/check-backup.sh` | Backup health check |

---

## Phase 2: Service API Layer → `service` Branch

### Headscale
- Keep SQLite config (no change)
- Init container copies template to config.yaml (simplified, no password inject)

### Backend Services (keep as-is)
- 8 services × Master + UAT = 16 backend containers
- `Dockerfile.backend` (generic .NET 8 builder)

### Jenkins
- `Dockerfile.jenkins` (keep as-is)
- `jenkins/init.groovy.d/` scripts (keep as-is)
- `jenkins/jobs/_templates/service-job-config.xml` (keep as-is)

### Prometheus
- `prometheus/prometheus.yml` (keep, add postgres scrape jobs back in Phase 1)
- `prometheus/rules/sts-alerts.yml` (keep)

### Files owned by `service` branch
| File | Description |
|------|-------------|
| `Dockerfile.backend` | .NET 8 builder |
| `Dockerfile.jenkins` | Jenkins with docker CLI |
| `jenkins/init.groovy.d/*` | Jenkins init scripts |
| `jenkins/jobs/_templates/*` | Jenkins job templates |
| `prometheus/prometheus.yml` | Prometheus scrape config |
| `prometheus/rules/*` | Prometheus alert rules |

---

## Phase 3: Web Layer → `web` Branch

### Nginx (keep as-is)
- `nginx-master` (port 82) + `nginx-uat` (port 81)
- `nginx-exporter-master` + `nginx-exporter-uat`

### Frontend (keep as-is)
- `sts-portal-master` + `sts-portal-uat` (Next.js)
- `Dockerfile.frontend`

### NEW: BFF Web Service
```
Dockerfile.bff-web:
- Node.js/Express or .NET 8
- Acts as BFF for browser clients
- Routes: /api/* → Service API Server
- Environment: per-env (Master|UAT)
```

### NEW: BFF Mobile Service
```
Dockerfile.bff-mobile:
- Node.js/Express or .NET 8
- Acts as BFF for mobile clients
- Routes: /api/* → Service API Server
- Mobile-specific transformations
```

### Files owned by `web` branch
| File | Description |
|------|-------------|
| `nginx.master.conf` | Nginx master config |
| `nginx.uat.conf` | Nginx UAT config |
| `Dockerfile.frontend` | Next.js builder |
| `Dockerfile.bff-web` | BFF Web builder |
| `Dockerfile.bff-mobile` | BFF Mobile builder |
| `sts-portal/` | Frontend source (cloned via bootstrap) |

---

## Phase 4: Common Files (all branches)

Files that exist in ALL branches (shared):
| File | Notes |
|------|-------|
| `docker-compose.yml` | Full compose with all layers |
| `.env.example` | All env vars |
| `.gitignore` | Shared ignore rules |
| `bootstrap.ps1` | Clone all repos + create dirs |
| `bootstrap.sh` | Same for Linux |
| `Dockerfile.backend` | Needed by all (service depends on it) |
| `Dockerfile.frontend` | Needed by all (web depends on it) |
| `Dockerfile.jenkins` | Needed by all (CI/CD) |

---

## Execution Order

```
1. Switch to main → create db branch  → add PostgreSQL, pgAdmin, backup
2. Switch to main → create web branch → add BFF Dockerfiles + compose services
3. Switch to main → keep service branch (already has backend/headscale/jenkins)
4. Prune branches:
   - `db`: remove web/service specific files (nginx/, frontend/, jenkins/)
   - `service`: remove db/web specific files (pgadmin/, backup/, nginx.*.conf, Dockerfile.frontend)
   - `web`: remove db/service specific files (pgadmin/, backup/, jenkins/)
   Exception: docker-compose.yml stays full in all branches
```

## Phase 5: BFF Implementation Detail

### docker-compose additions
```yaml
bff-web-master:
  build:
    context: .
    dockerfile: Dockerfile.bff-web
  container_name: sts-bff-web-master
  depends_on: [sts-adm-master]
  networks: [sts-net]

bff-web-uat:
  build:
    context: .
    dockerfile: Dockerfile.bff-web
  container_name: sts-bff-web-uat
  depends_on: [sts-adm-uat]
  networks: [sts-net]

# Same pattern for bff-mobile
```

### Nginx routing update
- nginx.master.conf + nginx.uat.conf → proxy `/api/*` → BFF instead of directly to Service API
- BFF then proxies to appropriate backend service

### Dockerfile.bff-web / Dockerfile.bff-mobile
- Multi-stage build (Node.js or .NET)
- Exposes port 80
- Proxy logic (express-http-proxy or YARP)
