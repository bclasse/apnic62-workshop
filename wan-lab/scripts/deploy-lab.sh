#!/usr/bin/env bash
# Deploy or reset the APNIC62 WAN lab for a given lab number (1-5).
set -euo pipefail

LAB_NUM="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAN_LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${WAN_LAB_DIR}/.." && pwd)"
LICENSE_FILE="${REPO_ROOT}/srl-license/srlinux.license"
CLAB_FILE="${WAN_LAB_DIR}/apnic62-wan.clab.yml"
ACTIVE_DIR="${WAN_LAB_DIR}/configs/active"

usage() {
  echo "Usage: $0 <lab-number>"
  echo "  lab-number: 1-5"
  echo ""
  echo "Example: $0 1"
  exit 1
}

[[ -n "${LAB_NUM}" ]] || usage
[[ "${LAB_NUM}" =~ ^[1-5]$ ]] || usage

if [[ ! -f "${LICENSE_FILE}" ]]; then
  echo "ERROR: Nokia license file not found at:"
  echo "  ${LICENSE_FILE}"
  echo ""
  echo "Place the license file provided by workshop organizers before deploying."
  exit 1
fi

LAB_CONFIG_DIR="${WAN_LAB_DIR}/configs/lab${LAB_NUM}-start"
if [[ ! -d "${LAB_CONFIG_DIR}" ]]; then
  echo "ERROR: Lab config directory not found: ${LAB_CONFIG_DIR}"
  echo "Run: python3 scripts/generate-configs.py"
  exit 1
fi

echo "==> Preparing active configs from lab${LAB_NUM}-start"
mkdir -p "${ACTIVE_DIR}"
rm -f "${ACTIVE_DIR}"/*.cfg
cp "${LAB_CONFIG_DIR}"/*.cfg "${ACTIVE_DIR}/"

cd "${WAN_LAB_DIR}"

if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q '^clab-apnic62-wan-'; then
  echo "==> Destroying existing lab"
  clab destroy -t "${CLAB_FILE}" --cleanup || true
fi

echo "==> Deploying lab ${LAB_NUM}"
clab deploy -t "${CLAB_FILE}" --reconfigure

echo ""
echo "Lab ${LAB_NUM} deployed. Connect to student routers:"
echo "  ssh admin@r1-p1"
echo "  ssh admin@r5-pe1"
echo "  ssh admin@r9-ce1"
echo ""
echo "Default password: NokiaSrl1!"
