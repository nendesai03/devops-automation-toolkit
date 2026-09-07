# DevOps Automation Toolkit

A collection of production-tested automation scripts for cloud cost control, 
backup reliability, monitoring hygiene, and CI/CD workflows — built from 
real infrastructure work across AWS, Azure, and Kubernetes environments.

🔗 [Portfolio & freelance services](https://portfolio-website-lovat-six-95.vercel.app/)
📧 nenjdesai2000@gmail.com

---

## Why this exists

Most cloud waste and security gaps come from small things nobody automates — 
unused resources quietly costing money, overly permissive IAM policies, 
storage buckets with no lifecycle management. These scripts solve specific, 
recurring problems I've run into managing production infrastructure.

---

## Scripts

| Script | Category | What it solves | Status |
|---|---|---|---|
| [aws-unused-resources-finder](./aws/unused-resources-finder) | Cost | Flags idle EBS volumes, unattached EIPs, low-utilization EC2 instances | ✅ |
| [aws-s3-lifecycle-audit](./aws/s3-lifecycle-audit) | Cost | Flags buckets missing lifecycle policies, unmanaged versioning, stale multipart uploads | ✅ |
| [iam-policy-auditor](./aws/iam-policy-auditor) | Security | Flags IAM policies with wildcard actions or resources | ✅ |
| [azure-orphaned-resources-cleanup](./azure/orphaned-resources-cleanup) | Cost | Finds unused NICs, public IPs, and disks | 🔜 |
| [db-backup-automation](./backup/db-backup-automation) | Reliability | Scheduled DB backups with cloud upload + rotation | 🔜 |
| [cert-expiry-checker](./monitoring/cert-expiry-checker) | Monitoring | Alerts before SSL certs expire | 🔜 |
| [log-rotation-cleanup](./monitoring/log-rotation-cleanup) | Monitoring | Rotates and archives logs past size/age thresholds | 🔜 |
| [pipeline-notification-bot](./cicd/pipeline-notification-bot) | CI/CD | Sends formatted build/deploy status to Slack/Teams | 🔜 |
| [docker-image-cleanup](./cicd/docker-image-cleanup) | CI/CD | Prunes old/unused Docker images on build servers | 🔜 |

---

## How to use

Each script folder has its own README with setup, usage, and sample output. 
All scripts are plain Bash — no dependencies beyond AWS CLI v2 and `jq` 
(and `bc` for the resource finder). Read-only by design: nothing here 
modifies or deletes cloud resources, they only report findings.

---

## About me

Senior DevOps Engineer with 5+ years across AWS, Azure, GCP, and Kubernetes. 
Available for freelance and contract engagements — hourly or fixed-scope.

[View full portfolio →](https://portfolio-website-lovat-six-95.vercel.app/)