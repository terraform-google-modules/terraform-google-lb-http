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

function checkPattern() {
  local URL=$1
  local pattern="$2"
  local count=0
  while [[ $count -lt 120 ]]; do
    echo "INFO: Checking ${URL} for text: '$pattern'..."
    if curl -sfkL -m 5 "${URL}" | egrep -q "${pattern}"; then
      echo "INFO: PASS. Found pattern: '$pattern'"
      return 0
    fi
    ((count=count+1))
    sleep 5
  done
  return 1
}

checkPattern ${URL}/group1 "$(terraform output group1_region)"
checkPattern ${URL}/group2 "$(terraform output group2_region)"
checkPattern ${URL}/group3 "$(terraform output group3_region)"

status=0
status=$(curl -sfk -m 5 -o /dev/null -w "%{http_code}" "$(terraform output asset-url)" || true)
if [[ $status -eq 200 ]]; then
  echo "INFO: PASS. Assets served from GCS bucket."
else
  echo "ERROR: Failed, could not get asset from bucket."
  exit 1
fi

echo "INFO: PASS"