#!/bin/sh
set -eu

BACKUP_DIR="${BACKUP_DIR:-/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/sts_uat_${TIMESTAMP}.sql.gz"

mkdir -p "${BACKUP_DIR}"

if command -v pg_dump >/dev/null 2>&1; then
    echo "Starting PostgreSQL dump..."
    PGPASSWORD="${POSTGRES_PASSWORD:-}" pg_dump \
        -h "${PG_HOST:-postgres_uat}" \
        -p "${PG_PORT:-5432}" \
        -U "${PG_USER:-userSTS}" \
        -d "${PG_DATABASE:-STS}" \
        --no-owner \
        --no-acl \
        | gzip > "${BACKUP_FILE}"

    echo "Backup saved: ${BACKUP_FILE} ($(du -h "${BACKUP_FILE}" | cut -f1))"
else
    echo "pg_dump not available; copying from backup-source..."
    if [ -d "/backup-source" ] && [ "$(ls -A /backup-source 2>/dev/null)" ]; then
        cp -r /backup-source/* "${BACKUP_DIR}/"
        echo "Copied backup-source to ${BACKUP_DIR}"
    else
        echo "WARN: No backup source available. Skipping."
        exit 0
    fi
fi

find "${BACKUP_DIR}" -name "sts_uat_*.sql.gz" -mtime "+${RETENTION_DAYS}" -delete
echo "Cleaned up backups older than ${RETENTION_DAYS} days."
