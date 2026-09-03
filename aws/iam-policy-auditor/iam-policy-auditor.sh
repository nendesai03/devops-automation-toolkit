#!/usr/bin/env bash
#
# iam-policy-auditor.sh
# Scans customer-managed and inline IAM policies for overly permissive
# wildcard actions or resources.
#
# Usage: ./iam-policy-auditor.sh

set -euo pipefail

echo "Starting IAM policy audit..."
echo "-------------------------------------------"

command -v aws >/dev/null 2>&1 || { echo "Error: AWS CLI not found."; exit 1; }
command -v jq  >/dev/null 2>&1 || { echo "Error: jq not found."; exit 1; }

total_policies=0
issues_found=0

# --- 1. Audit customer-managed policies ---
echo ""
echo "Checking customer-managed policies..."

policy_arns=$(aws iam list-policies \
  --scope Local \
  --query 'Policies[].Arn' \
  --output text)

for arn in $policy_arns; do
  total_policies=$((total_policies+1))
  policy_name=$(basename "$arn")

  default_version=$(aws iam get-policy \
    --policy-arn "$arn" \
    --query 'Policy.DefaultVersionId' \
    --output text)

  doc=$(aws iam get-policy-version \
    --policy-arn "$arn" \
    --version-id "$default_version" \
    --query 'PolicyVersion.Document' \
    --output json)

  # Normalize: Statement can be a single object or an array
  statements=$(echo "$doc" | jq -c 'if (.Statement | type) == "array" then .Statement[] else .Statement end')

  while read -r stmt; do
    [ -z "$stmt" ] && continue
    effect=$(echo "$stmt" | jq -r '.Effect')
    [ "$effect" != "Allow" ] && continue

    action=$(echo "$stmt" | jq -c '.Action')
    resource=$(echo "$stmt" | jq -c '.Resource')

    if echo "$action" | grep -q '"\*"'; then
      echo "[WILDCARD ACTION]     policy: ${policy_name}        |  Statement allows Action: \"*\""
      issues_found=$((issues_found+1))
    fi

    if echo "$resource" | grep -q '"\*"'; then
      echo "[WILDCARD RESOURCE]    policy: ${policy_name}          |  Statement allows Resource: \"*\""
      issues_found=$((issues_found+1))
    fi
  done < <(echo "$statements")
done

# --- 2. Audit inline policies on IAM users ---
echo ""
echo "Checking inline policies on IAM users..."

users=$(aws iam list-users --query 'Users[].UserName' --output text)

for user in $users; do
  inline_policy_names=$(aws iam list-user-policies \
    --user-name "$user" \
    --query 'PolicyNames' \
    --output text)

  for policy_name in $inline_policy_names; do
    [ -z "$policy_name" ] && continue
    total_policies=$((total_policies+1))

    doc=$(aws iam get-user-policy \
      --user-name "$user" \
      --policy-name "$policy_name" \
      --query 'PolicyDocument' \
      --output json)

    statements=$(echo "$doc" | jq -c 'if (.Statement | type) == "array" then .Statement[] else .Statement end')

    while read -r stmt; do
      [ -z "$stmt" ] && continue
      effect=$(echo "$stmt" | jq -r '.Effect')
      [ "$effect" != "Allow" ] && continue

      action=$(echo "$stmt" | jq -c '.Action')
      resource=$(echo "$stmt" | jq -c '.Resource')

      if echo "$action" | grep -q '"\*"' || echo "$resource" | grep -q '"\*"'; then
        echo "[INLINE WILDCARD]      user: ${user}                 |  Inline policy: ${policy_name}"
        issues_found=$((issues_found+1))
      fi
    done < <(echo "$statements")
  done
done

echo ""
echo "-------------------------------------------"
echo "Audit complete — ${issues_found} issue(s) found across ${total_policies} policies scanned."