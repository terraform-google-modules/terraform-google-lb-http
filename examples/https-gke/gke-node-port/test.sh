#!/usr/bin/env bash

set -x 
set -e

EXP_NAME=$(terraform output port_name)
EXP_PORT=$(terraform output port_number)
INSTANCE_GROUP=$(terraform output instance_group)
NAMED_PORTS="$(gcloud compute instance-groups get-named-ports ${INSTANCE_GROUP} --format=json | jq -r '.[]|"\(.name)=\(.port)"' | tr '\n' ';')"

MATCH="${EXP_NAME}=${EXP_PORT}"
if [[ "${NAMED_PORTS}" =~ $MATCH ]]; then
  echo "PASS: Found named port: $MATCH"
else
  echo "FAIL: Named port not found: $MATCH"
  exit 1
fi