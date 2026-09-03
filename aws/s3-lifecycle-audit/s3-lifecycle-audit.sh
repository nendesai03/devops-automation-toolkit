#!/usr/bin/env bash
#
# s3-lifecycle-audit.sh
# Audits all S3 buckets in an AWS account for missing lifecycle policies,
# unmanaged versioning, and stale incomplete multipart uploads.
#
# Usage: ./s3-lifecycle-audit.sh

set -euo pipefail

STALE_UPLOAD_DAYS=7

echo "Starting S3 lifecycle audit..."
echo "-------------------------------------------"

# Check dependencies
command -v aws >/dev/null 2>&1 || { echo "Error: AWS CLI not found."; exit 1; }
command -v jq  >/dev/null 2>&1 || { echo "Error: jq not found."; exit 1; }

total_buckets=0
flagged_buckets=0

buckets=$(aws s3api list-buckets --query 'Buckets[].Name' --output text)

for bucket in $buckets; do
  total_buckets=$((total_buckets+1))
  flagged=false

  # Check lifecycle configuration ---
  lifecycle=$(aws s3api get-bucket-lifecycle-configuration \
    --bucket "$bucket" 2>/dev/null || echo "")

  if [ -z "$lifecycle" ]; then
    echo "[NO LIFECYCLE POLICY]     ${bucket}"
    flagged=true
  fi

  # Check versioning without lifecycle cleanup ---
  versioning=$(aws s3api get-bucket-versioning \
    --bucket "$bucket" \
    --query 'Status' \
    --output text 2>/dev/null || echo "None")

  if [ "$versioning" == "Enabled" ] && [ -z "$lifecycle" ]; then
    echo "[VERSIONING, NO CLEANUP]  ${bucket}  |  Versioning: Enabled  |  No expiration rule"
    flagged=true
  fi

  # Check for stale incomplete multipart uploads ---
  uploads=$(aws s3api list-multipart-uploads \
    --bucket "$bucket" \
    --query 'Uploads[].{Key:Key,Initiated:Initiated}' \
    --output json 2>/dev/null || echo "[]")

  while read -r upload; do
    [ -z "$upload" ] && continue
    key=$(echo "$upload" | jq -r '.Key')
    initiated=$(echo "$upload" | jq -r '.Initiated')

    initiated_epoch=$(date -d "$initiated" +%s 2>/dev/null || \
                       date -j -f "%Y-%m-%dT%H:%M:%S" "${initiated%%.*}" +%s 2>/dev/null || echo 0)
    now_epoch=$(date +%s)
    age_days=$(( (now_epoch - initiated_epoch) / 86400 ))

    if [ "$age_days" -ge "$STALE_UPLOAD_DAYS" ]; then
      echo "[STALE MULTIPART UPLOAD]  ${bucket}  |  Key: ${key}  |  Age: ${age_days} days"
      flagged=true
    fi
  done < <(echo "$uploads" | jq -c '.[]')

  if [ "$flagged" = true ]; then
    flagged_buckets=$((flagged_buckets+1))
  fi
done

echo ""
echo "-------------------------------------------"
echo "Audit complete — ${flagged_buckets} bucket(s) flagged out of ${total_buckets} scanned."