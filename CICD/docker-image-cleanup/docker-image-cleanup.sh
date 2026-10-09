#!/usr/bin/env bash
#
# docker-image-cleanup.sh
# Removes old, unused Docker images. Dry-run by default.
#
# Usage: ./docker-image-cleanup.sh [days] [--apply]

set -euo pipefail

DAYS=30
APPLY=false

for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=true ;;
    ''|*[!0-9]*) echo "Usage: $0 [days] [--apply]"; exit 1 ;;
    *) DAYS="$arg" ;;
  esac
done

command -v docker >/dev/null 2>&1 || { echo "Error: docker not found."; exit 1; }
docker info >/dev/null 2>&1 || { echo "Error: cannot reach the Docker daemon."; exit 1; }

if [ "$APPLY" = true ]; then
  echo "Mode: APPLY (images older than ${DAYS} days will be deleted)"
else
  echo "Mode: DRY-RUN (nothing will be deleted; use --apply to delete)"
fi
echo "-------------------------------------------"

# Collect IDs of images used by any container (running or stopped)
used_ids=""
for container in $(docker ps -a -q); do
  used_ids+="$(docker inspect -f '{{.Image}}' "$container")"$'\n'
done

now_epoch=$(date +%s)
count=0
total_bytes=0

for id in $(docker images -q --no-trunc | sort -u); do
  # Skip images in use by a container
  if echo "$used_ids" | grep -qx "$id"; then
    continue
  fi

  created=$(docker image inspect -f '{{.Created}}' "$id")
  created_clean="${created%%.*}"
  created_clean="${created_clean%Z}"

  created_epoch=$(date -u -d "${created_clean}Z" +%s 2>/dev/null || \
                  date -j -u -f "%Y-%m-%dT%H:%M:%S" "$created_clean" +%s 2>/dev/null || echo "$now_epoch")
  age_days=$(( (now_epoch - created_epoch) / 86400 ))

  [ "$age_days" -lt "$DAYS" ] && continue

  name=$(docker image inspect -f '{{if .RepoTags}}{{index .RepoTags 0}}{{else}}<dangling>{{end}}' "$id")
  bytes=$(docker image inspect -f '{{.Size}}' "$id")
  size_mb=$(( bytes / 1024 / 1024 ))

  if [ "$APPLY" = true ]; then
    if docker rmi "$id" >/dev/null 2>&1; then
      echo "[REMOVED]       ${name}  |  Age: ${age_days} days  |  Size: ${size_mb} MB"
      count=$((count+1))
      total_bytes=$((total_bytes+bytes))
    else
      echo "[SKIPPED]       ${name}  |  Could not remove (still referenced)"
    fi
  else
    echo "[WOULD REMOVE]  ${name}  |  Age: ${age_days} days  |  Size: ${size_mb} MB"
    count=$((count+1))
    total_bytes=$((total_bytes+bytes))
  fi
done

total_mb=$(( total_bytes / 1024 / 1024 ))

echo ""
echo "-------------------------------------------"
if [ "$APPLY" = true ]; then
  echo "Cleanup complete — ${count} image(s) removed, ~${total_mb} MB reclaimed."
else
  echo "Dry run complete — ${count} image(s), ~${total_mb} MB could be reclaimed. Re-run with --apply to delete."
fi