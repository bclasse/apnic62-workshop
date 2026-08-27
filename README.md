# APNIC62 - Next-Gen Service Provider Routing Workshop

Hands-on workshop covering **Segment Routing**, **SR-MPLS traffic engineering**, and **EVPN-MPLS** on Nokia SR Linux — delivered at APNIC62.

This repository is the containerlab companion to the printed guide *Nokia SR Linux Segment Routing and EVPN for WAN – APNIC62 Workshop Lab Guide*. The five labs and their exercises follow the guide exactly.

## Quick start

```bash
git clone https://github.com/thcorre/apnic62-workshop.git
cd apnic62-workshop
# Place your Nokia license at srl-license/srlinux.license (provided by organizers)
cd wan-lab
./scripts/deploy-lab.sh 1
ssh admin@clab-apnic62-wan-lab-r5-pe1
```

Default credentials: `admin` / `NokiaSrl1!`

Run `./scripts/deploy-lab.sh <N>` to load lab **N**'s start configuration before beginning that lab.

## Lab guides

| Lab | Title | Duration |
|-----|-------|----------|
| [Lab 1](wan-lab/lab1-isis-sr-evpn-bgp.md) | Configuration of IS-IS to support Segment Routing and MP-BGP sessions for EVPN | ~120 min |
| [Lab 2](wan-lab/lab2-te-link-attributes.md) | Configuration and advertisement of traffic engineering link attributes | ~45 min |
| [Lab 3](wan-lab/lab3-sr-te-policies.md) | Configuration of segment routing tunnels with traffic engineering (uncolored SR-MPLS TE policy) | ~180 min |
| [Lab 4](wan-lab/lab4-evpn-elan.md) | Configuration of EVPN ELAN | ~90 min |
| [Lab 5](wan-lab/lab5-evpn-multihoming.md) | Configuration of EVPN multi-homing in ELAN | ~150 min |

**Start here:** [wan-lab/README.md](wan-lab/README.md)

## Lab environments

The guide presents the same 12 routers through two views:

- **Segment routing lab environment** — 12 × 7250 IXR routers (four CE, four PE, four P). Used by all of Labs 1, 2 and 3.
- **EVPN lab environment** — six of the same routers. PE1–PE4 are the segment routing view's provider edge routers R5–R8 and keep their `system0.0` addresses, so the loopbacks run `10.10.10.5/32`–`10.10.10.8/32`.

## Prerequisites

- Linux host (or WSL2) with Docker and [containerlab](https://containerlab.dev/)
- **12× IXR-X1B** containers: ~24–36 GB RAM, 12+ vCPUs recommended
- Nokia SR Linux **license file** (`ixr-x1b` requires a license — provided by workshop organizers)
- SR Linux image: `ghcr.io/nokia/srlinux:26.7`

## Documentation

- [Topology and addressing](docs/topology.md)
- [Lab guide router mapping](docs/router-naming.md)
