# AWS S3 Lifecycle Audit

Scans all S3 buckets in an AWS account and flags buckets missing lifecycle 
policies, versioning, or with incomplete multipart uploads sitting around — 
common sources of silent storage cost creep.

## Problem

S3 costs quietly grow when buckets have no lifecycle rules to transition 
old data to cheaper storage classes or delete it, no versioning cleanup, 
and abandoned multipart uploads that were never completed or aborted.

## What it checks

- Buckets with no lifecycle configuration at all
- Buckets with versioning enabled but no lifecycle rule to expire old versions
- Buckets with incomplete multipart uploads older than 7 days

## Requirements

- AWS CLI v2 installed and configured (`aws configure`)
- `jq` installed
- Read-only IAM permissions for S3

## Usage

```bash
chmod +x s3-lifecycle-audit.sh
./s3-lifecycle-audit.sh
```

No region flag needed — S3 bucket listing is global, though each bucket's 
requests are routed to its own region automatically.


## Notes

Read-only by design — this script only reports findings, it never modifies 
bucket configuration or deletes any data.