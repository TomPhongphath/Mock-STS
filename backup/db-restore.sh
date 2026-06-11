#!/bin/sh
set -eu

if [ $# -lt 1 ]; then
    echo "Usage: $0 <backup-file>"
    echo "Example: $0 /backups/sts_uat_20240101_120000.sql.gz"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "${BACKUP_FILE}" ]; then
    echo "ERROR: Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

echo "WARN: This will overwrite the current database!"
echo "Target: ${PG_HOST:-postgres_uat}:${PG_PORT:-5432}/${PG_DATABASE:-STS}"
echo "File: ${BACKUP_FILE}"
echo "Press Ctrl+C within 5 seconds to cancel..."
sleep 5

if command -v psql >/dev/null 2>&1; then
    PGPASSWORD="${POSTGRES_PASSWORD:-}" gunzip -c "${BACKUP_FILE}" | psql \
        -h "${PG_HOST:-postgres_uat}" \
        -p "${PG_PORT:-5432}" \
        -U "${PG_USER:-userSTS}" \
        -d "${PG_DATABASE:-STS}"

    echo "Restore completed from: ${BACKUP_FILE}"
else
    echo "ERROR: psql not available. Install postgresql-client."
    exit 1
fi
