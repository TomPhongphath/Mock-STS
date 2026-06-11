# Plan: Full Sync Mock-STS → D:\mock-jenkins

## Constraints
- Keep Headscale (do NOT remove)
- Use env vars for secrets (NOT Docker secrets, NOT hardcoded plaintext)

---

## 1. Nginx — Split to master/uat

### Changes
1. Remove single `nginx_gateway` container
2. Add `nginx-master` (port 82) + `nginx-uat` (port 81) containers
3. Add `nginx-exporter-master` + `nginx-exporter-uat` (Prometheus exporters)
4. Delete `nginx/` directory (nginx.conf, conf.d/sts.conf)
5. Create `nginx.master.conf` at root (adapted from D:\mock-jenkins)
6. Create `nginx.uat.conf` at root (adapted from D:\mock-jenkins)

### Files
| Action | File | Source |
|--------|------|--------|
| DELETE | `nginx/nginx.conf` | — |
| DELETE | `nginx/conf.d/sts.conf` | — |
| DELETE | `nginx/conf.d/` (dir) | — |
| CREATE | `nginx.master.conf` | D:\mock-jenkins\nginx.master.conf |
| CREATE | `nginx.uat.conf` | D:\mock-jenkins\nginx.uat.conf |
| MODIFY | `docker-compose.yml` | Replace `nginx_gateway` → `nginx-master` + `nginx-uat` |

---

## 2. Jenkins — Dockerfile + Script Sync

### Changes
1. Create `Dockerfile.jenkins` (lts-jdk21, pre-install docker-ce-cli, remove runtime entrypoint)
2. Update compose: remove `entrypoint`, use `build: Dockerfile.jenkins`
3. Update `disable-security-for-mock.groovy` — remove `setCrumbIssuer(null)`
4. Update `seed-freestyle-job.groovy` — use `updateByXml`, add `sts-portal`, remove `SERVICE_PORT`/upstream triggers/`ensure_common_repo`
5. Update `service-job-config.xml` — `docker compose` v2, no upstream, poll `H/2 * * * *`, remove `ensure_common_repo`, add branch-not-found skip for `auto`

### Files
| Action | File | Source |
|--------|------|--------|
| CREATE | `Dockerfile.jenkins` | D:\mock-jenkins\Dockerfile.jenkins |
| MODIFY | `docker-compose.yml` | Use build: Dockerfile.jenkins, remove entrypoint, update env |
| MODIFY | `jenkins/init.groovy.d/disable-security-for-mock.groovy` | Remove CSRF disable |
| MODIFY | `jenkins/init.groovy.d/seed-freestyle-job.groovy` | Use updateByXml, 10 services incl. sts-portal |
| MODIFY | `jenkins/jobs/_templates/service-job-config.xml` | docker compose v2, H/2, no upstream |

---

## 3. docker-compose.yml — Major Restructure

### Service changes

| Service | Mock-STS (current) | D:\mock-jenkins (target) |
|---------|-------------------|-------------------------|
| PostgreSQL UAT | `postgres:15-alpine`, port 5431, `postgres_uat_data` vol | `postgres:17-alpine`, port 5433, `data/pgdata_uat` bind |
| PostgreSQL Master | `postgres:15-alpine`, port 5433, `postgres_master_data` vol | `postgres:17-alpine`, port 5432, `data/pgdata_master` bind |
| pgAdmin | env vars + servers.json + pgpass | simpler env, servers.json only, `PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED: False` |
| Headscale | **KEEP** existing config (do not remove) | — |
| Nginx | `nginx_gateway` | `nginx-master` (port 82) + `nginx-uat` (port 81) |
| Backend services | — | 7 services: `sts-noc-master`, `sts-alert-master`, `sts-teleport-master`, `sts-dashboard-master`, `sts-master-master`, `sts-adm-master`, `sts-install-master` + UAT variants |
| Frontend | — | `sts-portal-master` + `sts-portal-uat` |
| Monitoring | — | Prometheus + nginx-exporters + postgres-exporters |
| Backup | — | Backup container |
| Secrets | Docker secrets `postgres_password`, `pgadmin_password` | Remove → use env vars |

### Infrastructure changes

| Item | Current | Target |
|------|---------|--------|
| Network name | `sts-backend` | `sts-net` |
| PG image | `postgres:15-alpine` | `postgres:17-alpine` |
| PG UAT port | 5431 | 5433 |
| PG Master port | 5433 | 5432 |
| Docker secrets | `secrets:` block + secret files | REMOVE, use env vars |

### Headscale adaptation
Since Headscale stays but network changes:
- Add Headscale to `sts-net` network
- Update `headscale-init` to use env var for PG password (remove secret mount)
- Container names with underscores (`postgres_uat`) can stay since Headscale config references them

### pgAdmin adaptation
- Update `servers.json` host names if PG service names change
- Update compose to remove `secrets:` and pgpass if switching to non-pgpass auth

### Decision: Service naming convention
- **Keep existing underscore names** for PostgreSQL (`postgres_uat`, `postgres_master`) to avoid breaking Headscale config and servers.json
- New services (backend, etc.) use hyphen convention as in D:\mock-jenkins (e.g., `sts-adm-master`)

---

## 4. New Files — Backend/Frontend Dockerfiles

### Dockerfile.backend (generic .NET 8 builder)
- Accept `PROJECT_PATH` and `CSPROJ_FILE` as build args
- Multi-stage: `dotnet restore` → `dotnet publish` → runtime image
- Not present in D:\mock-jenkins root but referenced in compose

### Dockerfile.frontend (generic Next.js builder)
- Multi-stage: Node build → nginx or standalone runner
- Not present in D:\mock-jenkins root but referenced in compose

### Files
| Action | File | Notes |
|--------|------|-------|
| CREATE | `Dockerfile.backend` | Generic .NET 8 build + runtime |
| CREATE | `Dockerfile.frontend` | Generic Next.js build + runtime |

---

## 5. Monitoring (Prometheus)

### Files
| Action | File | Source |
|--------|------|--------|
| CREATE | `prometheus/prometheus.yml` | D:\mock-jenkins\prometheus.yml |
| CREATE | `prometheus/rules/sts-alerts.yml` | D:\mock-jenkins\prometheus\rules\sts-alerts.yml |

### compose additions
- `prometheus` service
- Postgres exporters (master + uat)

---

## 6. Backup System

### Files
| Action | File | Source |
|--------|------|--------|
| CREATE | `backup/db-backup.sh` | New — backup script |
| CREATE | `backup/db-restore.sh` | New — restore script |
| CREATE | `backup/check-backup.sh` | New — health check script |

### compose additions
- `backup` container (alpine-based, runs scripts)

---

## 7. Bootstrap Scripts

### Files
| Action | File | Source |
|--------|------|--------|
| CREATE | `bootstrap.ps1` | Adapted from D:\mock-jenkins (update repo owners) |
| CREATE | `bootstrap.sh` | Adapted from D:\mock-jenkins (update repo owners) |

### Bootstrap logic
- Clone all 10 repos from GitHub (use `TomPhongphath` owner for all)
- Create persistent data dirs: `data/pgdata_master`, `data/pgdata_uat`, `backups`
- Create `.env` from `.env.example` if not exists

---

## 8. .env.example Update

Replace current `.env.example` with variables matching new compose:
- PostgreSQL ports (5432/5433)
- Nginx ports (82/81)
- pgAdmin email/password
- GITHUB_TOKEN
- Jenkins port
- Headscale port

---

## 9. File Cleanup

| Action | File |
|--------|------|
| DELETE | `secrets/` directory |
| DELETE | `nginx/` directory |
| DELETE | `.md` (draft notes file) |
| MODIFY | `.gitignore` — add `data/`, `backups/`, `prometheus/data/` |

---

## Execution Order

```
Phase 1: Infrastructure — docker-compose.yml restructure (new services, network, PG)
Phase 2: Nginx — create configs, remove old
Phase 3: Jenkins — Dockerfile + init scripts + template
Phase 4: Dockerfiles — Dockerfile.backend, Dockerfile.frontend
Phase 5: Monitoring — prometheus config + rules
Phase 6: Backup — scripts + container
Phase 7: Bootstrap — ps1 + sh scripts
Phase 8: Env — .env.example refresh
Phase 9: Cleanup — remove old files, update .gitignore
```

Each phase is independent of the others except Phase 1 (compose restructure) must be done first since Phase 2-7 all depend on it.
