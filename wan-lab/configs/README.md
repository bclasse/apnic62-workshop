# Startup configurations

Per-lab SR Linux startup configs in CLI `set` format for containerlab.

## Layout

| Directory | Purpose |
|-----------|---------|
| `lab1-start/` … `lab5-start/` | Starting state for each workshop lab (12 nodes each) |

All 5 labs now share a single containerlab topology file, `apnic62-wan-lab.clab.yml` (nodes and links are identical across labs; only the startup configs differ). The topology references startup configs via a stable `configs/active` symlink, which `deploy-lab.sh` points at the selected lab's config directory:

```yaml
startup-config: configs/active/__clabNodeName__.cfg
```

Config files use hierarchical SR Linux CLI `set` commands (same style as [srl-telemetry-lab](https://github.com/srl-labs/srl-telemetry-lab)).

| Lab | Config directory |
|-----|-------------------|
| 1 | `configs/lab1-start/` |
| 2 | `configs/lab2-start/` |
| 3 | `configs/lab3-start/` |
| 4 | `configs/lab4-start/` |
| 5 | `configs/lab5-start/` |

## Deploying and reloading

```bash
./scripts/deploy-lab.sh <N>            # full destroy + deploy for lab <N>
./scripts/deploy-lab.sh <N> --reload   # push lab <N>'s configs into the already-running lab, no redeploy
```

`--reload` applies each node's `.cfg` as a batch of `set` commands against the running candidate datastore and commits. It cannot remove config that was deleted from the `.cfg` file, and it won't pick up topology/wiring changes (those still need a full redeploy).

## Regenerate

Note: `generate-configs.ps1`/`.py` and `generate-clab-yml.ps1` predate the many manual config changes made since (e.g. `mac-vrf-1`/`mac-vrf-10` naming, per-lab TE/BGP additions) and `generate-clab-yml.ps1` still emits 5 separate topology files. Treat these as historical scaffolding rather than a reliable regeneration path until they are updated to match the current config/topology structure.

```powershell
# Windows
.\scripts\generate-configs.ps1
.\scripts\generate-clab-yml.ps1

# Linux / macOS (requires Python 3)
python3 scripts/generate-configs.py
```
