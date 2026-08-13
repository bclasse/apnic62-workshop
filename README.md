# APNIC62 Nokia SR Linux WAN Workshop

Hands-on workshop covering **Segment Routing**, **SR-MPLS traffic engineering**, and **EVPN-MPLS** on Nokia SR Linux — delivered at APNIC62.

## Quick start

```bash
git clone https://github.com/thcorre/apnic62-workshop.git
cd apnic62-workshop
# Place your Nokia license at srl-license/srlinux.license (provided by organizers)
cd wan-lab
./scripts/deploy-lab.sh 1
ssh admin@r5-pe1
```

Default credentials: `admin` / `NokiaSrl1!`

## Lab guides

| Lab | Topic | Duration |
|-----|-------|----------|
| [Lab 1](wan-lab/lab1-isis-sr-evpn-bgp.md) | IS-IS Segment Routing + MP-BGP for EVPN | ~120 min |
| [Lab 2](wan-lab/lab2-te-link-attributes.md) | TE Link Attributes | ~45 min |
| [Lab 3](wan-lab/lab3-sr-te-policies.md) | Uncolored SR-MPLS TE Policies | ~180 min |
| [Lab 4](wan-lab/lab4-evpn-elan.md) | EVPN ELAN | ~90 min |
| [Lab 5](wan-lab/lab5-evpn-multihoming.md) | EVPN Multi-homing ELAN | ~150 min |

**Start here:** [wan-lab/README.md](wan-lab/README.md)

## Prerequisites

- Linux host (or WSL2) with Docker and [containerlab](https://containerlab.dev/)
- **12× IXR-X1B** containers: ~24–36 GB RAM, 12+ vCPUs recommended
- Nokia SR Linux **license file** (`ixr-x1b` requires a license — provided by workshop organizers)
- SR Linux image: `ghcr.io/nokia/srlinux:25.3`

## Transport policy

This workshop uses **SR-ISIS** as the sole MPLS transport. **LDP is not used.**

## Documentation

- [Topology and addressing](docs/topology.md)
- [EVPN guide → SR topology router mapping](docs/router-naming.md)

