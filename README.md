# DevOps Automation Toolkit

A collection of automation scripts for cloud cost control, security auditing, 
backup reliability, monitoring hygiene, and CI/CD workflows — built from 
real infrastructure work across AWS, Azure, and Kubernetes environments.

🔗 [Portfolio & freelance services](https://portfolio-website-lovat-six-95.vercel.app/)
📧 nenjdesai2000@gmail.com

---

## Why this exists

Most cloud waste, security gaps, and outages come from small things nobody 
automates — unused resources quietly costing money, overly permissive IAM 
policies, storage buckets with no lifecycle management, certs expiring 
without warning, backups that never get taken, build servers running out of 
disk. These scripts solve specific, recurring problems I've run into managing 
production infrastructure.

---

## Scripts

| Script | Category | What it solves | Behavior |
|---|---|---|---|
| [aws-unused-resources-finder](./aws/unused-resources-finder) | Cost | Flags idle EBS volumes, unattached EIPs, low-utilization EC2 instances | Read-only |
| [s3-lifecycle-audit](./aws/s3-lifecycle-audit) | Cost | Flags buckets missing lifecycle policies, unmanaged versioning, stale multipart uploads | Read-only |
| [iam-policy-auditor](./aws/iam-policy-auditor) | Security | Flags IAM policies with wildcard actions or resources | Read-only |
| [cert-expiry-checker](./monitoring/cert-expiry-checker) | Monitoring | Flags SSL certificates nearing expiry | Read-only |
| [db-backup-automation](./backup/db-backup-automation) | Reliability | PostgreSQL/MySQL backups with optional S3 upload and local rotation | Writes backup files |
| [docker-image-cleanup](./cicd/docker-image-cleanup) | CI/CD | Removes old, unused Docker images from build servers | Dry-run by default; deletes only with `--apply` |

**Planned:** Azure orphaned-resource cleanup.

---

## Quick start

```bash
git clone https://github.com/<your-username>/devops-automation-toolkit.git
cd devops-automation-toolkit

# Example: scan an AWS region for unused resources
cd aws/unused-resources-finder
chmod +x find-unused-resources.sh
./find-unused-resources.sh us-east-1
```

---

## How to use

Each script folder has its own README with setup, usage, and sample output. 
All scripts are plain Bash. Dependencies vary per script (AWS CLI v2, `jq`, 
`openssl`, `bc`, Docker, `pg_dump`/`mysqldump`), so check the script's README 
first.

The AWS audit scripts and the certificate checker only report findings and 
never modify anything. The backup script writes backup files, and the Docker 
cleanup script deletes images only when run with `--apply`. Review any script 
and run it in a non-production environment before using it on live systems.

---

## About me

Senior DevOps Engineer with 5+ years across AWS, Azure, GCP, and Kubernetes. 
Available for freelance and contract engagements — hourly or fixed-scope.

[View full portfolio →](https://portfolio-website-lovat-six-95.vercel.app/)