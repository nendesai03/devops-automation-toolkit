#!/usr/bin/env bash
#
# cert-expiry-checker.sh
# Checks SSL certificate expiry for a list of domains and flags any
# expiring within a configurable warning threshold.
#
# Usage: ./cert-expiry-checker.sh <domains-file> [warning-days]

set -euo pipefail

DOMAINS_FILE="${1:-}"
WARNING_DAYS="${2:-14}"

if [ -z "$DOMAINS_FILE" ] || [ ! -f "$DOMAINS_FILE" ]; then
  echo "Usage: $0 <domains-file> [warning-days]"
  echo "Error: domains file not found or not provided."
  exit 1
fi

command -v openssl >/dev/null 2>&1 || { echo "Error: openssl not found."; exit 1; }

echo "Checking certificates (warning threshold: ${WARNING_DAYS} days)..."
echo "-------------------------------------------"

ok_count=0
warning_count=0
error_count=0

while IFS= read -r domain || [ -n "$domain" ]; do
  # Skip empty lines and comments
  [ -z "$domain" ] && continue
  [[ "$domain" =~ ^#.*$ ]] && continue

  expiry_date=$(echo | timeout 10 openssl s_client -servername "$domain" -connect "${domain}:443" 2>/dev/null \
    | openssl x509 -noout -enddate 2>/dev/null \
    | cut -d= -f2)

  if [ -z "$expiry_date" ]; then
    echo "[ERROR]   ${domain}        |  Connection failed — host unreachable"
    error_count=$((error_count+1))
    continue
  fi

  expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$expiry_date" +%s 2>/dev/null)
  now_epoch=$(date +%s)
  days_remaining=$(( (expiry_epoch - now_epoch) / 86400 ))
  expiry_short=$(date -d "$expiry_date" +%Y-%m-%d 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$expiry_date" +%Y-%m-%d 2>/dev/null)

  if [ "$days_remaining" -le "$WARNING_DAYS" ]; then
    echo "[WARNING] ${domain}    |  Expires: ${expiry_short}  |  ${days_remaining} days remaining"
    warning_count=$((warning_count+1))
  else
    echo "[OK]      ${domain}        |  Expires: ${expiry_short}  |  ${days_remaining} days remaining"
    ok_count=$((ok_count+1))
  fi

done < "$DOMAINS_FILE"

echo ""
echo "-------------------------------------------"
echo "Check complete — ${warning_count} warning(s), ${error_count} error(s), ${ok_count} healthy certificate(s)."