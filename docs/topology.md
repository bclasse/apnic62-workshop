# Lab topology and addressing

The APNIC62 WAN lab uses the **12-router topology** from the Nokia SR Linux Segment Routing for WAN lab guide.

## Roles

| Role | Routers | system0.0 |
|------|---------|-----------|
| Provider (P) | R1-P1 … R4-P4 | 10.10.10.1 – 10.10.10.4 |
| Provider edge (PE) | R5-PE1 … R8-PE4 | 10.10.10.5 – 10.10.10.8 |
| Customer edge (CE) | R9-CE1 … R12-CE4 | 10.10.10.9 – 10.10.10.12 |

Containerlab node names use lowercase with hyphens: `r1-p1`, `r5-pe1`, `r9-ce1`, etc.

## ASCII topology

```
                    ┌─────────┐     ┌─────────┐
                    │  R2-P2  │─────│  R6-PE2 │──── R10-CE2
                    └────┬────┘     └────┬────┘
                         │               │
     ┌─────────┐    ┌────┴────┐     ┌────┴────┐    ┌─────────┐
     │  R1-P1  │────│  R5-PE1 │     │  R7-PE3 │────│  R9-CE1 │
     └────┬────┘    └────┬────┘     └────┬────┘    └─────────┘
          │              │               │
     ┌────┴────┐    ┌────┴────┐     ┌────┴────┐
     │  R3-P3  │────│  R4-P4  │─────│  R8-PE4 │
     └─────────┘    └─────────┘     └─────────┘
```

P routers form a partial mesh among P and PE routers. R5-PE1 reaches the core only via R1-P1 and R2-P2 (no direct links to R3-P3 or R4-P4). R6-PE2 has no direct links to R3-P3 or R4-P4. R8-PE4 reaches the core via R3-P3 and R4-P4 (no direct link to R2-P2). CE routers attach to PE routers (R9 dual-homed to R5 and R7 for Lab 5; R11-CE3 to R7-PE3).

## Addressing rules

### Loopback (system0.0)

`10.10.10.x/32` where **x** is the router number (1–12).

Example: R5-PE1 → `10.10.10.5/32`

### Point-to-point links

`10.x.y.z/27` where:

- **x** = lower router number
- **y** = higher router number  
- **z** = this router's number

Example: link between R2 and R6 — on R2: `10.2.6.2/27`, on R6: `10.2.6.6/27`

### R1-P1 interface mapping (SR lab guide Figure 2)

| Interface | Peer | Subnet |
|-----------|------|--------|
| ethernet-1/1 | R5-PE1 | 10.1.5.0/27 |
| ethernet-1/2 | R2-P2 | 10.1.2.0/27 |
| ethernet-1/3 | R3-P3 | 10.1.3.0/27 |
| ethernet-1/4 | R4-P4 | 10.1.4.0/27 |
| ethernet-1/5 | R6-PE2 | 10.1.6.0/27 |

### R5-PE1 and R6-PE2 (Figure 2)

| Router | ethernet-1/1 | ethernet-1/2 | ethernet-1/5 |
|--------|--------------|--------------|--------------|
| R5-PE1 | R1-P1 (core) | R9-CE1 (VLAN access) | R2-P2 (core) |
| R6-PE2 | R1-P1 (core) | R10-CE2 | R2-P2 (core) |

### R2-P2 (Figure 2)

| Interface | Peer |
|-----------|------|
| ethernet-1/1 | R6-PE2 |
| ethernet-1/2 | R1-P1 |
| ethernet-1/3 | R4-P4 |
| ethernet-1/4 | R3-P3 |
| ethernet-1/5 | R5-PE1 |

### R3-P3 / R4-P4 / R7-PE3 / R8-PE4 (Figure 2)

| Router | eth-1/1 | eth-1/2 | eth-1/3 | eth-1/4 | eth-1/5 | eth-1/6 | eth-1/7 |
|--------|---------|---------|---------|---------|---------|---------|---------|
| R3-P3 | R7 | R4 | R1 | R2 | R8 | — | — |
| R4-P4 | R8 | R3 | R2 | R1 | R7 | — | — |
| R7-PE3 | R3 | R4 | R9 CE | R11 CE | — | — |
| R8-PE4 | R3 | R4 | — | — | R12 CE | — |

## Underlay

- **IGP:** IS-IS level-2 on all P and PE routers
- **MPLS transport:** SR-ISIS only (no LDP in this workshop)
- **EVPN control plane:** MP-iBGP (AS 65530) among PE routers

## Platform

All nodes run as **7250 IXR-X1B** (`type: ixr-x1b`) in containerlab with a valid Nokia license file.

## Related

- [EVPN → SR router name mapping](router-naming.md)
- [Deploy the lab](../wan-lab/README.md)
