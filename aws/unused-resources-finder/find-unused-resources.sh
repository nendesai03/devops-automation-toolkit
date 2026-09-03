#!/usr/bin/env bash
#
# find-unused-resources.sh
# Scans an AWS region for commonly-forgotten resources that cost money:
# unattached EBS volumes, unassociated Elastic IPs, and low-CPU EC2 instances.
#
# Usage: ./find-unused-resources.sh <aws-region>

set -euo pipefail

REGION="${1:-us-east-1}"
CPU_THRESHOLD=5          # percent
LOOKBACK_DAYS=14

echo "Scanning region: ${REGION}"
echo "-------------------------------------------"

# Check dependencies
command -v aws >/dev/null 2>&1 || { echo "Error: AWS CLI not found."; exit 1; }
command -v jq  >/dev/null 2>&1 || { echo "Error: jq not found."; exit 1; }
command -v bc  >/dev/null 2>&1 || { echo "Error: bc not found."; exit 1; }

ebs_count=0
eip_count=0
low_cpu_count=0

# Unattached EBS volumes ---
echo ""
echo "Checking for unattached EBS volumes..."

volumes=$(aws ec2 describe-volumes \
  --region "$REGION" \
  --filters Name=status,Values=available \
  --query 'Volumes[].{ID:VolumeId,Size:Size,Created:CreateTime}' \
  --output json)

while read -r vol; do
  [ -z "$vol" ] && continue
  id=$(echo "$vol" | jq -r '.ID')
  size=$(echo "$vol" | jq -r '.Size')
  created=$(echo "$vol" | jq -r '.Created' | cut -d'T' -f1)
  echo "[UNUSED EBS VOLUME]   ${id}  |  Size: ${size} GiB  |  Created: ${created}"
  ebs_count=$((ebs_count+1))
done < <(echo "$volumes" | jq -c '.[]')

# Unassociated Elastic IPs ---
echo ""
echo "Checking for unassociated Elastic IPs..."

eips=$(aws ec2 describe-addresses \
  --region "$REGION" \
  --query 'Addresses[?AssociationId==null].{IP:PublicIp}' \
  --output json)

while read -r eip; do
  [ -z "$eip" ] && continue
  ip=$(echo "$eip" | jq -r '.IP')
  echo "[UNUSED ELASTIC IP]   ${ip}  |  Not associated with any instance"
  eip_count=$((eip_count+1))
done < <(echo "$eips" | jq -c '.[]')

# Low-utilization EC2 instances ---
echo ""
echo "Checking for low-utilization EC2 instances (last ${LOOKBACK_DAYS} days)..."

instance_ids=$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters Name=instance-state-name,Values=running \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text)

start_time=$(date -u -d "-${LOOKBACK_DAYS} days" +%Y-%m-%dT%H:%M:%S 2>/dev/null || \
             date -u -v-${LOOKBACK_DAYS}d +%Y-%m-%dT%H:%M:%S)
end_time=$(date -u +%Y-%m-%dT%H:%M:%S)

for instance_id in $instance_ids; do
  instance_type=$(aws ec2 describe-instances \
    --region "$REGION" \
    --instance-ids "$instance_id" \
    --query 'Reservations[0].Instances[0].InstanceType' \
    --output text)

  avg_cpu=$(aws cloudwatch get-metric-statistics \
    --region "$REGION" \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value="$instance_id" \
    --start-time "$start_time" \
    --end-time "$end_time" \
    --period 86400 \
    --statistics Average \
    --query 'Datapoints[].Average' \
    --output text | awk '{sum+=$1; count+=1} END {if(count>0) printf "%.1f", sum/count; else print "0"}')

  if (( $(echo "$avg_cpu < $CPU_THRESHOLD" | bc -l) )); then
    echo "[LOW UTILIZATION EC2] ${instance_id}  |  Type: ${instance_type}  |  Avg CPU (${LOOKBACK_DAYS}d): ${avg_cpu}%"
    low_cpu_count=$((low_cpu_count+1))
  fi
done

echo ""
echo "-------------------------------------------"
echo "Scan complete — ${ebs_count} unused EBS volume(s), ${eip_count} unused Elastic IP(s), ${low_cpu_count} low-utilization instance(s) flagged."