# AWS Unused Resources Finder

Scans an AWS account and flags resources that are commonly forgotten and 
quietly cost money: unattached EBS volumes, unassociated Elastic IPs, and 
EC2 instances with sustained low CPU utilization.

## Problem

Idle EBS volumes, unused Elastic IPs, and oversized EC2 instances are one 
of the most common sources of avoidable AWS spend — and they're easy to 
miss without regular auditing.

## What it checks

- EBS volumes not attached to any instance
- Elastic IPs not associated with a running instance
- EC2 instances with sustained low CPU utilization over the last 14 days 
  (via CloudWatch)

## Requirements

- AWS CLI v2 installed and configured (`aws configure`)
- `jq` installed
- Read-only IAM permissions for EC2 and CloudWatch

## Usage

```bash
chmod +x find-unused-resources.sh
./find-unused-resources.sh us-east-1
```

## Notes

Read-only by design — this script only reports findings, it never deletes 
or modifies any resource.