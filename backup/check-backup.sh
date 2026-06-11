#!/bin/sh
set -eu

BACKUP_DIR="${BACKUP_DIR:-/backups}"
METRICS_FILE="${METRICS_FILE:-/var/tmp/backup-metrics.prom}"
BACKUP_WINDOW_HOURS="${BACKUP_WINDOW_HOURS:-25}"

mkdir -p "$(dirname "${METRICS_FILE}")"

LATEST=$(find "${BACKUP_DIR}" -name "sts_uat_*.sql.gz" -type f 2>/dev/null | sort | tail -1)

if [ -n "${LATEST}" ]; then
    NOW=$(date +%s)
    FILE_TIME=$(stat -c %Y "${LATEST}" 2>/dev/null || stat -f %m "${LATEST}" 2>/dev/null)
    AGE=$(( (NOW - FILE_TIME) / 3600 ))

    if [ "${AGE}" -le "${BACKUP_WINDOW_HOURS}" ]; then
        echo "sts_backup_ok 1" > "${METRICS_FILE}"
        echo "sts_backup_age_seconds $(( NOW - FILE_TIME ))" >> "${METRICS_FILE}"
        echo "OK: Latest backup is ${AGE}h old (threshold ${BACKUP_WINDOW_HOURS}h)"
    else
        echo "sts_backup_ok 0" > "${METRICS_FILE}"
        echo "WARN: Latest backup is ${AGE}h old (threshold ${BACKUP_WINDOW_HOURS}h)"
    fi
else
    echo "sts_backup_ok 0" > "${METRICS_FILE}"
    echo "WARN: No backup files found in ${BACKUP_DIR}"
fi

echo "sts_backup_files $(find "${BACKUP_DIR}" -name 'sts_uat_*.sql.gz' -type f 2>/dev/null | wc -l)" >> "${METRICS_FILE}"
