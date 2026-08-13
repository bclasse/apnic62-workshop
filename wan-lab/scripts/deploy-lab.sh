#!/usr/bin/env bash
# Deploy or reset the APNIC62 WAN lab for a given lab number (1-5).
set -euo pipefail

LAB_NUM="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAN_LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${WAN_LAB_DIR}/.." && pwd)"
LICENSE_FILE="${REPO_ROOT}/srl-license/srlinux.license"
CLAB_FILE="${WAN_LAB_DIR}/apnic62-wan-lab${LAB_NUM}.clab.yml"
LAB_CONFIG_DIR="${WAN_LAB_DIR}/configs/lab${LAB_NUM}-start"
DEBUG_LOG="${REPO_ROOT}/debug-984e35.log"

# #region agent log
debug_log() {
  local hypothesis_id="$1"
  local location="$2"
  local message="$3"
  local data_json="$4"
  printf '{"sessionId":"984e35","runId":"deploy","hypothesisId":"%s","location":"%s","message":"%s","data":%s,"timestamp":%s}\n' \
    "$hypothesis_id" "$location" "$message" "$data_json" "$(date +%s%3N)" >> "${DEBUG_LOG}"
}
# #endregion

usage() {
  echo "Usage: $0 <lab-number>"
  echo "  lab-number: 1-5"
  echo ""
  echo "Example: $0 1"
  exit 1
}

[[ -n "${LAB_NUM}" ]] || usage
[[ "${LAB_NUM}" =~ ^[1-5]$ ]] || usage

# #region agent log
debug_log "H1" "deploy-lab.sh:paths" "resolved deploy paths" \
  "{\"wanLabDir\":\"${WAN_LAB_DIR}\",\"clabFile\":\"${CLAB_FILE}\",\"labConfigDir\":\"${LAB_CONFIG_DIR}\"}"
# #endregion

if [[ ! -f "${LICENSE_FILE}" ]]; then
  echo "ERROR: Nokia license file not found at:"
  echo "  ${LICENSE_FILE}"
  echo ""
  echo "Place the license file provided by workshop organizers before deploying."
  exit 1
fi

if [[ ! -f "${CLAB_FILE}" ]]; then
  echo "ERROR: Containerlab topology file not found: ${CLAB_FILE}"
  echo "Run: powershell -File scripts/generate-clab-yml.ps1 (or use committed .clab.yml files)"
  exit 1
fi

if [[ ! -d "${LAB_CONFIG_DIR}" ]]; then
  echo "ERROR: Lab config directory not found: ${LAB_CONFIG_DIR}"
  exit 1
fi

missing_cfg=0
for node in r1-p1 r2-p2 r3-p3 r4-p4 r5-pe1 r6-pe2 r7-pe3 r8-pe4 r9-ce1 r10-ce2 r11-ce3 r12-ce4; do
  cfg="${LAB_CONFIG_DIR}/${node}.cfg"
  if [[ ! -f "${cfg}" ]]; then
    echo "ERROR: Missing startup config: ${cfg}"
    missing_cfg=1
  fi
done

# #region agent log
debug_log "H2" "deploy-lab.sh:configs" "startup config presence check" \
  "{\"labConfigDir\":\"${LAB_CONFIG_DIR}\",\"missingCfg\":${missing_cfg},\"sampleCfg\":\"${LAB_CONFIG_DIR}/r1-p1.cfg\",\"sampleExists\":$([[ -f \"${LAB_CONFIG_DIR}/r1-p1.cfg\" ]] && echo true || echo false)}"
# #endregion

if [[ "${missing_cfg}" -ne 0 ]]; then
  exit 1
fi

invalid_isis=0
if grep -q "protocols isis admin-state enable" "${LAB_CONFIG_DIR}"/*.cfg 2>/dev/null; then
  invalid_isis=1
fi

# #region agent log
debug_log "H3" "deploy-lab.sh:validate-isis" "check for invalid protocols isis admin-state line" \
  "{\"labConfigDir\":\"${LAB_CONFIG_DIR}\",\"invalidIsisAdminState\":${invalid_isis}}"
# #endregion

if [[ "${invalid_isis}" -ne 0 ]]; then
  echo "ERROR: Invalid startup config: 'protocols isis admin-state enable' is not valid SR Linux syntax."
  echo "Regenerate configs with: powershell -File scripts/generate-configs.ps1"
  exit 1
fi

cd "${WAN_LAB_DIR}"

# Destroy any previously deployed APNIC62 WAN lab topology (lab1-lab5).
for n in 1 2 3 4 5; do
  prev="${WAN_LAB_DIR}/apnic62-wan-lab${n}.clab.yml"
  if [[ -f "${prev}" ]]; then
    clab destroy -t "${prev}" --cleanup 2>/dev/null || true
  fi
done

# #region agent log
debug_log "H3" "deploy-lab.sh:deploy" "starting clab deploy" \
  "{\"clabFile\":\"${CLAB_FILE}\",\"cwd\":\"$(pwd)\"}"
# #endregion

echo "==> Deploying lab ${LAB_NUM} from ${CLAB_FILE}"
set +e
clab deploy -t "${CLAB_FILE}" --reconfigure --max-workers 4
deploy_rc=$?
set -e

if [[ "${deploy_rc}" -ne 0 ]]; then
  # #region agent log
  debug_log "H5" "deploy-lab.sh:failed" "clab deploy failed" "{\"labNum\":${LAB_NUM},\"exitCode\":${deploy_rc}}"
  # #endregion
  echo ""
  echo "Deploy failed (exit ${deploy_rc}). Collecting diagnostics..."
  bash "${SCRIPT_DIR}/collect-deploy-diagnostics.sh" "${LAB_NUM}" || true
  exit "${deploy_rc}"
fi

# #region agent log
debug_log "H4" "deploy-lab.sh:done" "clab deploy finished" "{\"labNum\":${LAB_NUM}}"
# #endregion

echo ""
echo "Lab ${LAB_NUM} deployed. Connect to student routers:"
echo "  ssh admin@r1-p1"
echo "  ssh admin@r5-pe1"
echo "  ssh admin@r9-ce1"
echo ""
echo "Default password: NokiaSrl1!"
