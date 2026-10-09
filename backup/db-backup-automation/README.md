# Database Backup Automation

Creates compressed backups of a PostgreSQL or MySQL database, optionally 
uploads them to S3, and deletes local backups older than a retention window.

## Problem

Manual or ad-hoc database backups get skipped, and nobody notices until a 
restore is needed. This script gives you one consistent, scriptable backup 
routine you can run from cron.

## What it does

- Dumps a PostgreSQL (custom format) or MySQL (gzip SQL) database
- Names each backup with a timestamp: `<db>_<YYYYmmdd_HHMMSS>.<ext>`
- Optionally uploads the backup to an S3 bucket
- Deletes local backups older than the retention period (default 7 days)
- Removes partial files if a dump fails

## Requirements

- PostgreSQL: `pg_dump` | MySQL: `mysqldump`
- AWS CLI v2 (only if uploading to S3)
- Database credentials via environment (never on the command line):
  - PostgreSQL: `PGPASSWORD` or a `~/.pgpass` file
  - MySQL: `MYSQL_PWD`

## Usage

```bash
chmod +x db-backup.sh

# PostgreSQL, local only
DB_USER=appuser PGPASSWORD='...' ./db-backup.sh postgres mydb

# MySQL, upload to S3, keep 14 days locally
DB_USER=appuser MYSQL_PWD='...' \
S3_BUCKET=s3://my-backups/mysql RETENTION_DAYS=14 \
./db-backup.sh mysql mydb
```

| Variable | Default | Purpose |
|---|---|---|
| `DB_HOST` | `localhost` | Database host |
| `DB_PORT` | 5432 / 3306 | Database port |
| `DB_USER` | `postgres` / `root` | Database user |
| `BACKUP_DIR` | `./backups` | Local backup directory |
| `RETENTION_DAYS` | `7` | Delete local backups older than this |
| `S3_BUCKET` | *(unset)* | e.g. `s3://bucket/prefix`. Upload if set |


## Notes

- Schedule with cron, e.g. `0 2 * * * /path/db-backup.sh postgres mydb`.
- Retention here applies to **local** files. For S3, use a bucket lifecycle 
  rule (see `aws/s3-lifecycle-audit` to find buckets missing one).
- Test a restore regularly. A backup you haven't restored isn't proven.