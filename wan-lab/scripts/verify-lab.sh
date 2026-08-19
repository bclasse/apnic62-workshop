#!/usr/bin/env bash
# Smoke-check that core lab nodes are reachable after deploy.
set -euo pipefail

LAB_NUM="${1:-1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAN_LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${WAN_LAB_DIR}"

echo "==> Checking containerlab lab status (active config: lab${LAB_NUM}-start)"
clab inspect -t "apnic62-wan-lab.clab.yml"

echo ""
echo "==> Checking IS-IS adjacencies on r1-p1"
docker exec "clab-apnic62-wan-lab-r1-p1" sr_cli -c \
  "show network-instance default protocols isis adjacency" || true

echo ""
echo "==> Checking IS-IS adjacencies on r5-pe1"
docker exec "clab-apnic62-wan-lab-r5-pe1" sr_cli -c \
  "show network-instance default protocols isis adjacency" || true

echo ""
echo "Smoke check complete."
