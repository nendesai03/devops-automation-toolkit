# Docker Image Cleanup

Finds (and optionally removes) old Docker images on a build server that are 
not used by any container, to reclaim disk space.

## Problem

CI/CD servers accumulate old images with every build until the disk fills 
up and pipelines start failing. This script prunes them safely.

## What it does

- Lists images older than N days (default 30)
- Skips any image used by a running or stopped container
- **Dry-run by default**: shows what would be removed and the space reclaimed
- Deletes only when you pass `--apply`

## Requirements

- Docker CLI with access to the Docker daemon

## Usage

```bash
chmod +x docker-image-cleanup.sh

./docker-image-cleanup.sh              # dry-run, images older than 30 days
./docker-image-cleanup.sh 14           # dry-run, older than 14 days
./docker-image-cleanup.sh 14 --apply   # actually delete
```