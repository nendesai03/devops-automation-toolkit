#!/usr/bin/env bash
#
# db-backup.sh
# Backs up a PostgreSQL or MySQL database, optionally uploads to S3,
# and rotates old local backups.
#
# Usage: ./db-backup.sh <postgres|mysql> <database-name>

set -euo pipefail

DB_TYPE="${1:-}"
DB_NAME="${2:-}"

if [ -z "$DB_TYPE" ] || [ -z "$DB_NAME" ]; then
  echo "Usage: $0 <postgres|mysql> <database-name>"
  exit 1
fi

DB_HOST="${DB_HOST:-localhost}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
S3_BUCKET="${S3_BUCKET:-}"

case "$DB_TYPE" in
  postgres)
    DB_PORT="${DB_PORT:-5432}"
    DB_USER="${DB_USER:-postgres}"
    EXT="dump"
    command -v pg_dump >/dev/null 2>&1 || { echo "Error: pg_dump not found."; exit 1; }
    ;;
  mysql)
    DB_PORT="${DB_PORT:-3306}"
    DB_USER="${DB_USER:-root}"
    EXT="sql.gz"
    command -v mysqldump >/dev/null 2>&1 || { echo "Error: mysqldump not found."; exit 1; }
    ;;
  *)
    echo "Error: database type must be 'postgres' or 'mysql'."
    exit 1
    ;;
esac

if [ -n "$S3_BUCKET" ]; then
  command -v aws >/dev/null 2>&1 || { echo "Error: AWS CLI not found (needed for S3_BUCKET)."; exit 1; }
fi

mkdir -p "$BACKUP_DIR"

timestamp=$(date +%Y%m%d_%H%M%S)
backup_file="${BACKUP_DIR}/${DB_NAME}_${timestamp}.${EXT}"

# Remove a partial backup file if anything fails mid-way
cleanup_on_error() {
  rm -f "$backup_file"
}
trap cleanup_on_error ERR

# --- 1. Dump ---
echo "[BACKUP]  Dumping ${DB_TYPE} database '${DB_NAME}' ..."

if [ "$DB_TYPE" == "postgres" ]; then
  pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -Fc "$DB_NAME" > "$backup_file"
else
  mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" \
    --single-transaction --routines --triggers "$DB_NAME" | gzip > "$backup_file"
fi

size=$(du -h "$backup_file" | cut -f1)
echo "[OK]      Created ${backup_file} (${size})"

# --- 2. Optional S3 upload ---
if [ -n "$S3_BUCKET" ]; then
  aws s3 cp "$backup_file" "${S3_BUCKET%/}/$(basename "$backup_file")" --only-show-errors
  echo "[UPLOAD]  Uploaded to ${S3_BUCKET%/}/$(basename "$backup_file")"
fi

# --- 3. Rotate old local backups ---
deleted=$(find "$BACKUP_DIR" -maxdepth 1 -type f -name "${DB_NAME}_*.${EXT}" \
  -mtime +"$RETENTION_DAYS" -print -delete | wc -l | tr -d ' ')
echo "[ROTATE]  Deleted ${deleted} local backup(s) older than ${RETENTION_DAYS} days"

trap - ERR
echo ""
echo "Backup complete."