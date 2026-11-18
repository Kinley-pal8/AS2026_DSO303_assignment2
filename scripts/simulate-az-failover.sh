#!/usr/bin/env bash
# Simulates losing the database's Availability Zone: forces an RDS Multi-AZ failover while
# polling the API's deep health check (which queries PostgreSQL through RDS Proxy) every 2 s.
# Output is a timeline saved to evidence/ and shown in a screenshot.
set -euo pipefail
cd "$(dirname "$0")/../infra"

APP_URL=$(terraform output -raw app_url)
DB_ID=$(terraform output -raw db_instance_id)
LOG="../evidence/az-failover-$(date +%Y%m%d-%H%M%S).log"

az_of() { aws rds describe-db-instances --db-instance-identifier "$DB_ID" \
  --query 'DBInstances[0].[AvailabilityZone,SecondaryAvailabilityZone]' --output text; }

echo "Before: primary/standby AZ = $(az_of)" | tee "$LOG"
aws rds reboot-db-instance --db-instance-identifier "$DB_ID" --force-failover >/dev/null
echo "$(date +%T) forced failover requested" | tee -a "$LOG"

down_since=""
for i in $(seq 1 150); do
  code=$(curl -s -o /tmp/health.json -w '%{http_code}' "$APP_URL/api/health?deep=1" || echo 000)
  echo "$(date +%T) HTTP $code $(cat /tmp/health.json 2>/dev/null)" | tee -a "$LOG"
  if [[ "$code" != "200" && -z "$down_since" ]]; then down_since=$(date +%s); fi
  status=$(aws rds describe-db-instances --db-instance-identifier "$DB_ID" --query 'DBInstances[0].DBInstanceStatus' --output text)
  if [[ "$status" == "available" && "$code" == "200" && $i -gt 10 ]]; then break; fi
  sleep 2
done

[[ -n "$down_since" ]] && echo "Database unavailable for ~$(( $(date +%s) - down_since ))s (upper bound)" | tee -a "$LOG"
echo "After: primary/standby AZ = $(az_of)" | tee -a "$LOG"
echo "Saved $LOG"
