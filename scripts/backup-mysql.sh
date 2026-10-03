#!/usr/bin/env bash
# Dump MySQL from docker compose to ./backups/
#
# Cron example (daily 03:15):
#   15 3 * * * /path/to/cardgame/scripts/backup-mysql.sh >> /var/log/cardgame-backup.log 2>&1
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${BACKUP_DIR:-${ROOT}/backups}"
mkdir -p "${OUT_DIR}"
OUT_FILE="${OUT_DIR}/cardgame-${STAMP}.sql.gz"

CONTAINER="${MYSQL_CONTAINER:-cardgame-mysql}"
MYSQL_USER="${MYSQL_USER:-cardgame}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-cardgame}"
MYSQL_DATABASE="${MYSQL_DATABASE:-cardgame}"

if ! docker ps --format '{{.Names}}' | grep -qx "${CONTAINER}"; then
  echo "MySQL container '${CONTAINER}' is not running" >&2
  exit 1
fi

docker exec "${CONTAINER}" \
  mysqldump -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" \
  --single-transaction --routines --triggers \
  "${MYSQL_DATABASE}" | gzip -c > "${OUT_FILE}"

echo "Wrote ${OUT_FILE}"

# Keep last 14 dumps by default
KEEP="${BACKUP_KEEP:-14}"
ls -1t "${OUT_DIR}"/cardgame-*.sql.gz 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -f
