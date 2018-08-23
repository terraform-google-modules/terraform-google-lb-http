#!/usr/bin/env bash

set -x 
set -e

URL="https://$(terraform output load-balancer-ip)"
status=0
count=0
while [[ $count -lt 720 && $status -ne 200 ]]; do
  echo "INFO: Waiting for load balancer..."
  status=$(curl -sfk -m 5 -o /dev/null -w "%{http_code}" "${URL}" || true)
  ((count=count+1))
  sleep 5
done
if [[ $count -lt 720 ]]; then
  echo "INFO: PASS. Load balancer is ready."
else
  echo "ERROR: Failed. Load balancer never became ready."
  exit 1
fi
