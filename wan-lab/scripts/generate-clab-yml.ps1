# Generate one containerlab topology file per workshop lab (1-5).
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

$links = @(
    '    - endpoints: ["r1-p1:e1-1", "r5-pe1:e1-1"]',
    '    - endpoints: ["r1-p1:e1-2", "r2-p2:e1-2"]',
    '    - endpoints: ["r1-p1:e1-3", "r3-p3:e1-1"]',
    '    - endpoints: ["r1-p1:e1-4", "r4-p4:e1-1"]',
    '    - endpoints: ["r1-p1:e1-5", "r6-pe2:e1-1"]',
    '    - endpoints: ["r2-p2:e1-1", "r6-pe2:e1-5"]',
    '    - endpoints: ["r2-p2:e1-4", "r3-p3:e1-2"]',
    '    - endpoints: ["r2-p2:e1-3", "r4-p4:e1-2"]',
    '    - endpoints: ["r2-p2:e1-5", "r5-pe1:e1-5"]',
    '    - endpoints: ["r3-p3:e1-3", "r4-p4:e1-3"]',
    '    - endpoints: ["r3-p3:e1-4", "r8-pe4:e1-1"]',
    '    - endpoints: ["r3-p3:e1-6", "r7-pe3:e1-1"]',
    '    - endpoints: ["r4-p4:e1-6", "r7-pe3:e1-2"]',
    '    - endpoints: ["r4-p4:e1-7", "r8-pe4:e1-2"]',
    '    - endpoints: ["r5-pe1:e1-2", "r9-ce1:e1-1"]',
    '    - endpoints: ["r6-pe2:e1-2", "r10-ce2:e1-1"]',
    '    - endpoints: ["r7-pe3:e1-3", "r9-ce1:e1-2"]',
    '    - endpoints: ["r7-pe3:e1-4", "r11-ce3:e1-1"]',
    '    - endpoints: ["r8-pe4:e1-6", "r12-ce4:e1-1"]'
)

$nodes = @(
    "r1-p1", "r2-p2", "r3-p3", "r4-p4", "r5-pe1", "r6-pe2",
    "r7-pe3", "r8-pe4", "r9-ce1", "r10-ce2", "r11-ce3", "r12-ce4"
)

foreach ($lab in 1..5) {
    $configDir = "configs/lab${lab}-start"
    $nodeBlocks = ($nodes | ForEach-Object { "    ${_}:" }) -join "`n"
    $content = @"
name: apnic62-wan-lab$lab

topology:
  defaults:
    kind: nokia_srlinux

  kinds:
    nokia_srlinux:
      type: ixr-x1b
      image: ghcr.io/nokia/srlinux:25.10
      license: ../srl-license/srlinux.license
      startup-config: ${configDir}/__clabNodeName__.cfg

  nodes:
$nodeBlocks

  links:
$($links -join "`n")
"@
    $out = Join-Path $Root "apnic62-wan-lab$lab.clab.yml"
    Set-Content -Path $out -Value $content -Encoding UTF8
    Write-Host "wrote $out"
}
