# AWS IAM Policy Auditor

Scans IAM policies across an AWS account and flags overly permissive 
statements — wildcard actions, wildcard resources, or both — that violate 
least-privilege best practices.

## Problem

Wildcard IAM permissions (`"Action": "*"` or `"Resource": "*"`) are one of 
the most common causes of security incidents in AWS. They're often added 
for convenience during development and never tightened afterward.

## What it checks

- Customer-managed IAM policies with `"Action": "*"`
- Customer-managed IAM policies with `"Resource": "*"`
- Inline policies attached directly to IAM users with the same issues

## Requirements

- AWS CLI v2 installed and configured (`aws configure`)
- `jq` installed
- Read-only IAM permissions (`iam:List*`, `iam:Get*`)

## Usage

```bash
chmod +x iam-policy-auditor.sh
./iam-policy-auditor.sh
```

## Notes

Read-only by design — this script only reports findings, it never modifies 
or removes any IAM policy or permission.