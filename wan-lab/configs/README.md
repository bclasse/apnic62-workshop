# Startup configurations

Per-lab SR Linux startup configs in CLI `set` format for containerlab.

## Layout

| Directory | Purpose |
|-----------|---------|
| `lab1-start/` … `lab5-start/` | Starting state for each workshop lab (12 nodes each) |

Each lab topology references startup configs via the containerlab node-name template:

```yaml
startup-config: configs/lab1-start/__clabNodeName__.cfg
```

Config files use hierarchical SR Linux CLI `set` commands (same style as [srl-telemetry-lab](https://github.com/srl-labs/srl-telemetry-lab)).

| Lab | Topology file | Config directory |
|-----|---------------|------------------|
| 1 | `apnic62-wan-lab1.clab.yml` | `configs/lab1-start/` |
| 2 | `apnic62-wan-lab2.clab.yml` | `configs/lab2-start/` |
| 3 | `apnic62-wan-lab3.clab.yml` | `configs/lab3-start/` |
| 4 | `apnic62-wan-lab4.clab.yml` | `configs/lab4-start/` |
| 5 | `apnic62-wan-lab5.clab.yml` | `configs/lab5-start/` |

## Regenerate

```powershell
# Windows
.\scripts\generate-configs.ps1
.\scripts\generate-clab-yml.ps1

# Linux / macOS (requires Python 3)
python3 scripts/generate-configs.py
```

After regenerating configs, redeploy with `./scripts/deploy-lab.sh <N>`.
