# SSL Certificate Expiry Checker

Checks SSL certificates for a list of domains and flags any expiring within 
a configurable threshold — before they cause an outage.

## Problem

Expired SSL certificates are one of the most common and entirely preventable 
causes of production downtime. Manual tracking across dozens of domains 
doesn't scale.

## What it checks

- Days remaining until certificate expiry for each domain in the list
- Flags any domain expiring within the warning threshold (default 14 days)
- Reports connection failures (unreachable host, invalid cert chain) separately

## Requirements

- `openssl` installed (available by default on most Linux/macOS systems)

## Usage

```bash
chmod +x cert-expiry-checker.sh
./cert-expiry-checker.sh domains.txt
```

Create a `domains.txt` file with one domain per line:

