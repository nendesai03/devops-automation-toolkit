# DevOps Automation Toolkit

A collection of production-tested automation scripts for cloud cost control, 
backup reliability, monitoring hygiene, and CI/CD workflows — built from 
real infrastructure work across AWS, Azure, and Kubernetes environments.

🔗 [Portfolio & freelance services](https://portfolio-website-lovat-six-95.vercel.app/)
📧 nenjdesai2000@gmail.com

---

## Why this exists

Most cloud waste and reliability gaps come from small things nobody automates — 
unused resources quietly costing money, certs expiring without warning, logs 
filling up disks. These scripts solve specific, recurring problems I've run 
into managing production infrastructure.

---

## Scripts

| Script | Category | What it solves |
|---|---|---|
| [aws-unused-resources-finder](./aws/unused-resources-finder) | Cost | Flags idle EBS volumes, unattached EIPs, oversized EC2 instances |
| [aws-s3-lifecycle-audit](./aws/s3-lifecycle-audit) | Cost | Reports buckets missing lifecycle policies or versioning |
| [azure-orphaned-resources-cleanup](./azure/orphaned-resources-cleanup) | Cost | Finds unused NICs, public IPs, and disks |
| [iam-policy-auditor](./aws/iam-policy-auditor) | Security | Scans IAM policies for overly permissive rules |
| [db-backup-automation](./backup/db-backup-automation) | Reliability | Scheduled DB backups with cloud upload + rotation |
| [cert-expiry-checker](./monitoring/cert-expiry-checker) | Monitoring | Alerts before SSL certs expire |
| [log-rotation-cleanup](./monitoring/log-rotation-cleanup) | Monitoring | Rotates and archives logs past size/age thresholds |
| [pipeline-notification-bot](./cicd/pipeline-notification-bot) | CI/CD | Sends formatted build/deploy status to Slack/Teams |
| [docker-image-cleanup](./cicd/docker-image-cleanup) | CI/CD | Prunes old/unused Docker images on build servers |

---

## How to use

Each script folder has its own README with setup, usage, and sample output. 
Most require only Python 3.8+ or Bash, plus relevant cloud CLI credentials 
(AWS CLI / Azure CLI configured).

---

## About me

Senior DevOps Engineer with 5+ years across AWS, Azure, GCP, and Kubernetes. 
Available for freelance and contract engagements — hourly or fixed-scope.

[View full portfolio →](https://portfolio-website-lovat-six-95.vercel.app/)