#!/usr/bin/env bash
# Deploy, reset, or reload the APNIC62 WAN lab for a given lab number (1-5).
#
# Usage:
#   deploy-lab.sh <lab-number>            Full destroy + deploy (recreates all containers)
#   deploy-lab.sh <lab-number> --reload   Push that lab's startup configs into the
#                                         already-running containers, without
#                                         destroying/recreating them.
#
# Notes on --reload:
#   - Only applies "set" lines from the .cfg files to the running candidate
#     datastore and commits them; it cannot remove config that is no longer
#     present in the .cfg file (there is no "delete" equivalent here).
#   - It does not pick up topology/wiring changes (new/removed links, port
#     renumbering) since containers are not recreated. Use a full (non
#     --reload) run for that.
#   - Nodes whose container isn't currently running are skipped with a
#     warning rather than aborting the whole run.
set -euo pipefail

LAB_NUM="${1:-}"
MODE="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAN_LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${WAN_LAB_DIR}/.." && pwd)"
LICENSE_FILE="${REPO_ROOT}/srl-license/srlinux.license"
CLAB_FILE="${WAN_LAB_DIR}/apnic62-wan-lab.clab.yml"
LAB_CONFIG_DIR="${WAN_LAB_DIR}/configs/lab${LAB_NUM}-start"
ACTIVE_CONFIG_LINK="${WAN_LAB_DIR}/configs/active"
LAB_NAME="apnic62-wan-lab"
NODES=(r1-p1 r2-p2 r3-p3 r4-p4 r5-pe1 r6-pe2 r7-pe3 r8-pe4 r9-ce1 r10-ce2 r11-ce3 r12-ce4)

usage() {
  echo "Usage: $0 <lab-number> [--reload]"
  echo "  lab-number: 1-5"
  echo "  --reload:   push config to already-running containers instead of a full redeploy"
  echo ""
  echo "Examples:"
  echo "  $0 1              # full destroy + deploy of lab 1"
  echo "  $0 3 --reload     # push lab 3's configs into the running lab, no redeploy"
  exit 1
}

[[ -n "${LAB_NUM}" ]] || usage
[[ "${LAB_NUM}" =~ ^[1-5]$ ]] || usage
[[ -z "${MODE}" || "${MODE}" == "--reload" ]] || usage

if [[ ! -f "${LICENSE_FILE}" ]]; then
  echo "ERROR: Nokia license file not found at:"
  echo "  ${LICENSE_FILE}"
  echo ""
  echo "Place the license file provided by workshop organizers before deploying."
  exit 1
fi

if [[ ! -f "${CLAB_FILE}" ]]; then
  echo "ERROR: Containerlab topology file not found: ${CLAB_FILE}"
  exit 1
fi

if [[ ! -d "${LAB_CONFIG_DIR}" ]]; then
  echo "ERROR: Lab config directory not found: ${LAB_CONFIG_DIR}"
  exit 1
fi

missing_cfg=0
for node in "${NODES[@]}"; do
  cfg="${LAB_CONFIG_DIR}/${node}.cfg"
  if [[ ! -f "${cfg}" ]]; then
    echo "ERROR: Missing startup config: ${cfg}"
    missing_cfg=1
  fi
done
[[ "${missing_cfg}" -eq 0 ]] || exit 1

if grep -q "protocols isis admin-state enable" "${LAB_CONFIG_DIR}"/*.cfg 2>/dev/null; then
  echo "ERROR: Invalid startup config: 'protocols isis admin-state enable' is not valid SR Linux syntax."
  exit 1
fi

# Point the shared topology's startup-config path at this lab's config directory.
ln -sfn "lab${LAB_NUM}-start" "${ACTIVE_CONFIG_LINK}"

cd "${WAN_LAB_DIR}"

if [[ "${MODE}" == "--reload" ]]; then
  echo "==> Reloading lab ${LAB_NUM} configs into running containers (no redeploy)"
  echo ""
  fail=0
  for node in "${NODES[@]}"; do
    container="clab-${LAB_NAME}-${node}"
    if ! docker inspect -f '{{.State.Running}}' "${container}" >/dev/null 2>&1; then
      echo "  [skip]  ${container} is not running"
      continue
    fi
    cfg="${LAB_CONFIG_DIR}/${node}.cfg"
    if { cat "${cfg}"; echo; echo "commit save"; } | docker exec -i "${container}" sr_cli -e >/tmp/"${node}"-reload.log 2>&1; then
      echo "  [ok]    ${node}"
    else
      echo "  [FAIL]  ${node} (see /tmp/${node}-reload.log)"
      fail=1
    fi
  done
  echo ""
  if [[ "${fail}" -ne 0 ]]; then
    echo "One or more nodes failed to reload. Check the logs referenced above."
    exit 1
  fi
  echo "Reload complete for lab ${LAB_NUM}."
  exit 0
fi

# Destroy any previously deployed instance of the shared topology.
clab destroy -t "${CLAB_FILE}" --cleanup 2>/dev/null || true

echo "==> Deploying lab ${LAB_NUM} from ${CLAB_FILE} (configs/active -> lab${LAB_NUM}-start)"
set +e
clab deploy -t "${CLAB_FILE}" --reconfigure --max-workers 4
deploy_rc=$?
set -e

if [[ "${deploy_rc}" -ne 0 ]]; then
  echo ""
  echo "Deploy failed (exit ${deploy_rc}). Collecting diagnostics..."
  bash "${SCRIPT_DIR}/collect-deploy-diagnostics.sh" "${LAB_NUM}" || true
  exit "${deploy_rc}"
fi

echo ""
echo "Lab ${LAB_NUM} deployed. Connect to student routers:"
if [[ "${LAB_NUM}" == "4" || "${LAB_NUM}" == "5" ]]; then
  echo "  ssh admin@clab-apnic62-wan-lab-r5-pe1"
  echo "  ssh admin@clab-apnic62-wan-lab-r7-pe3"
  echo "  ssh admin@clab-apnic62-wan-lab-r9-ce1"
else
  echo "  ssh admin@clab-apnic62-wan-lab-r1-p1"
  echo "  ssh admin@clab-apnic62-wan-lab-r5-pe1"
  echo "  ssh admin@clab-apnic62-wan-lab-r9-ce1"
fi
echo ""
echo "Default password: NokiaSrl1!"
