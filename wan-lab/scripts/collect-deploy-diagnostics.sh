#!/usr/bin/env bash
# Collect container/runtime evidence after a failed or partial deploy.
set -euo pipefail

LAB_NUM="${1:-1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAN_LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${WAN_LAB_DIR}/.." && pwd)"
LAB_NAME="apnic62-wan-lab"

cd "${WAN_LAB_DIR}"

running=0
exited=0
sample_exit_code="null"
sample_log_tail=""

while IFS= read -r name; do
  [[ -n "${name}" ]] || continue
  state="$(docker inspect -f '{{.State.Status}}' "${name}" 2>/dev/null || echo unknown)"
  exit_code="$(docker inspect -f '{{.State.ExitCode}}' "${name}" 2>/dev/null || echo -1)"
  if [[ "${state}" == "running" ]]; then
    running=$((running + 1))
  else
    exited=$((exited + 1))
    if [[ "${sample_exit_code}" == "null" ]]; then
      sample_exit_code="${exit_code}"
      sample_log_tail="$(docker logs --tail 30 "${name}" 2>&1 | tr '\n' ' ' | sed 's/"/\\"/g')"
    fi
  fi
done < <(docker ps -a --format '{{.Names}}' | grep "^clab-${LAB_NAME}-" || true)

mem_avail_kb="$(grep MemAvailable /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 0)"
license_path="${REPO_ROOT}/srl-license/srlinux.license"
license_exists=$([[ -f "${license_path}" ]] && echo true || echo false)
license_bytes=$([[ -f "${license_path}" ]] && wc -c < "${license_path}" || echo 0)

cfg="${WAN_LAB_DIR}/configs/lab${LAB_NUM}-start/r1-p1.cfg"
bom_present=false
if [[ -f "${cfg}" ]]; then
  if head -c 3 "${cfg}" | od -An -tx1 | grep -q 'ef bb bf'; then
    bom_present=true
  fi
fi

echo "==> Lab ${LAB_NUM} diagnostics"
echo "    running containers: ${running}"
echo "    exited containers:  ${exited}"
echo "    mem available (KB): ${mem_avail_kb}"
echo "    license present:    ${license_exists} (${license_bytes} bytes)"
echo "    UTF-8 BOM in r1-p1: ${bom_present}"
if [[ "${exited}" -gt 0 ]]; then
  echo ""
  echo "==> Exited nodes (name / exit code):"
  docker ps -a --format '{{.Names}} {{.Status}}' | grep "^clab-${LAB_NAME}-" || true
  echo ""
  echo "==> Sample logs from first exited node:"
  first_exited="$(docker ps -a --filter "status=exited" --format '{{.Names}}' | grep "^clab-${LAB_NAME}-" | head -1 || true)"
  if [[ -n "${first_exited}" ]]; then
    docker logs --tail 40 "${first_exited}" 2>&1 || true
  fi
fi
