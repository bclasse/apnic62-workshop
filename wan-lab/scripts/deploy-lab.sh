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

invalid_r5=0
if [[ -f "${LAB_CONFIG_DIR}/r5-pe1.cfg" ]]; then
  if grep -q "interface irb0 subinterface 1 type routed" "${LAB_CONFIG_DIR}/r5-pe1.cfg" 2>/dev/null; then
    invalid_r5=1
  fi
  if grep -q "encapsulation-type mpls" "${LAB_CONFIG_DIR}/r5-pe1.cfg" 2>/dev/null && \
     ! grep -q "allowed-tunnel-types" "${LAB_CONFIG_DIR}/r5-pe1.cfg" 2>/dev/null; then
    invalid_r5=1
  fi
  if grep -q "interface ethernet-1/2 vlan-tagging true" "${LAB_CONFIG_DIR}/r5-pe1.cfg" 2>/dev/null && \
     grep -q "interface ethernet-1/2 subinterface 0" "${LAB_CONFIG_DIR}/r5-pe1.cfg" 2>/dev/null; then
    invalid_r5=1
  fi
  if ! grep -q "interface ethernet-1/5 subinterface 0 ipv4 address 10.2.5.5/27" "${LAB_CONFIG_DIR}/r5-pe1.cfg" 2>/dev/null; then
    invalid_r5=1
  fi
  if grep -q "interface ethernet-1/2 subinterface 0 ipv4 address 10.2.5.5/27" "${LAB_CONFIG_DIR}/r5-pe1.cfg" 2>/dev/null; then
    invalid_r5=1
  fi
fi

invalid_r6=0
if [[ -f "${LAB_CONFIG_DIR}/r6-pe2.cfg" ]]; then
  if ! grep -q "interface ethernet-1/5 subinterface 0 ipv4 address 10.2.6.6/27" "${LAB_CONFIG_DIR}/r6-pe2.cfg" 2>/dev/null; then
    invalid_r6=1
  fi
  if grep -q "interface ethernet-1/2 subinterface 0 ipv4 address 10.2.6.6/27" "${LAB_CONFIG_DIR}/r6-pe2.cfg" 2>/dev/null; then
    invalid_r6=1
  fi
fi

# #region agent log
debug_log "H4" "deploy-lab.sh:validate-r5" "r5-pe1 ip-vrf startup config checks" \
  "{\"labNum\":${LAB_NUM},\"invalidR5Pe1\":${invalid_r5},\"invalidR6Pe2\":${invalid_r6}}"
# #endregion

if [[ "${invalid_r5}" -ne 0 ]]; then
  echo "ERROR: Invalid r5-pe1 startup config (irb0 type routed, MPLS without allowed-tunnel-types, vlan-tagging with subinterface 0, or wrong R2 port mapping)."
  echo "Regenerate configs with: powershell -File scripts/generate-configs.ps1"
  exit 1
fi

if [[ "${invalid_r6}" -ne 0 ]]; then
  echo "ERROR: Invalid r6-pe2 startup config (R2 link must be on ethernet-1/5 per SR lab guide)."
  echo "Regenerate configs with: powershell -File scripts/generate-configs.ps1"
  exit 1
fi

invalid_r1=0
if [[ -f "${LAB_CONFIG_DIR}/r1-p1.cfg" ]]; then
  if ! grep -q "interface ethernet-1/1 subinterface 0 ipv4 address 10.1.5.1/27" "${LAB_CONFIG_DIR}/r1-p1.cfg" 2>/dev/null; then
    invalid_r1=1
  fi
  if ! grep -q "interface ethernet-1/2 subinterface 0 ipv4 address 10.1.2.1/27" "${LAB_CONFIG_DIR}/r1-p1.cfg" 2>/dev/null; then
    invalid_r1=1
  fi
  if grep -q "interface ethernet-1/1 subinterface 0 ipv4 address 10.1.2.1/27" "${LAB_CONFIG_DIR}/r1-p1.cfg" 2>/dev/null; then
    invalid_r1=1
  fi
fi

# #region agent log
debug_log "H6" "deploy-lab.sh:validate-r1" "r1-p1 SR guide interface mapping checks" \
  "{\"labNum\":${LAB_NUM},\"invalidR1P1\":${invalid_r1}}"
# #endregion

if [[ "${invalid_r1}" -ne 0 ]]; then
  echo "ERROR: Invalid r1-p1 startup config (ethernet-1/1 must be 10.1.5.1 toward R5-PE1 per SR lab guide)."
  echo "Regenerate configs with: powershell -File scripts/generate-configs.ps1"
  exit 1
fi

invalid_r2=0
if [[ -f "${LAB_CONFIG_DIR}/r2-p2.cfg" ]]; then
  if ! grep -q "interface ethernet-1/1 subinterface 0 ipv4 address 10.2.6.2/27" "${LAB_CONFIG_DIR}/r2-p2.cfg" 2>/dev/null; then
    invalid_r2=1
  fi
  if ! grep -q "interface ethernet-1/2 subinterface 0 ipv4 address 10.1.2.2/27" "${LAB_CONFIG_DIR}/r2-p2.cfg" 2>/dev/null; then
    invalid_r2=1
  fi
  if ! grep -q "interface ethernet-1/4 subinterface 0 ipv4 address 10.2.3.2/27" "${LAB_CONFIG_DIR}/r2-p2.cfg" 2>/dev/null; then
    invalid_r2=1
  fi
  if ! grep -q "interface ethernet-1/5 subinterface 0 ipv4 address 10.2.5.2/27" "${LAB_CONFIG_DIR}/r2-p2.cfg" 2>/dev/null; then
    invalid_r2=1
  fi
  if grep -q "interface ethernet-1/1 subinterface 0 ipv4 address 10.1.2.2/27" "${LAB_CONFIG_DIR}/r2-p2.cfg" 2>/dev/null; then
    invalid_r2=1
  fi
fi

# #region agent log
debug_log "H7" "deploy-lab.sh:validate-r2" "r2-p2 SR guide interface mapping checks" \
  "{\"labNum\":${LAB_NUM},\"invalidR2P2\":${invalid_r2}}"
# #endregion

if [[ "${invalid_r2}" -ne 0 ]]; then
  echo "ERROR: Invalid r2-p2 startup config (interface-to-peer mapping must match SR lab guide Figure 2)."
  echo "Regenerate configs with: powershell -File scripts/generate-configs.ps1"
  exit 1
fi

invalid_r3=0
if [[ -f "${LAB_CONFIG_DIR}/r3-p3.cfg" ]]; then
  if ! grep -q "interface ethernet-1/1 subinterface 0 ipv4 address 10.3.7.3/27" "${LAB_CONFIG_DIR}/r3-p3.cfg" 2>/dev/null; then
    invalid_r3=1
  fi
  if ! grep -q "interface ethernet-1/2 subinterface 0 ipv4 address 10.3.4.3/27" "${LAB_CONFIG_DIR}/r3-p3.cfg" 2>/dev/null; then
    invalid_r3=1
  fi
  if ! grep -q "interface ethernet-1/3 subinterface 0 ipv4 address 10.1.3.3/27" "${LAB_CONFIG_DIR}/r3-p3.cfg" 2>/dev/null; then
    invalid_r3=1
  fi
  if ! grep -q "interface ethernet-1/4 subinterface 0 ipv4 address 10.2.3.3/27" "${LAB_CONFIG_DIR}/r3-p3.cfg" 2>/dev/null; then
    invalid_r3=1
  fi
  if ! grep -q "interface ethernet-1/5 subinterface 0 ipv4 address 10.3.8.3/27" "${LAB_CONFIG_DIR}/r3-p3.cfg" 2>/dev/null; then
    invalid_r3=1
  fi
  if grep -q "interface ethernet-1/1 subinterface 0 ipv4 address 10.1.3.3/27" "${LAB_CONFIG_DIR}/r3-p3.cfg" 2>/dev/null; then
    invalid_r3=1
  fi
fi

# #region agent log
debug_log "H8" "deploy-lab.sh:validate-r3" "r3-p3 SR guide interface mapping checks" \
  "{\"labNum\":${LAB_NUM},\"invalidR3P3\":${invalid_r3}}"
# #endregion

if [[ "${invalid_r3}" -ne 0 ]]; then
  echo "ERROR: Invalid r3-p3 startup config (interface-to-peer mapping must match SR lab guide Figure 2)."
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
