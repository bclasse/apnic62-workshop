# 🔧 Lab 1: IS-IS Segment Routing + MP-BGP for EVPN

> **Foundation: SR underlay and EVPN control plane**

Configure IS-IS segment routing on the provider core, establish MP-BGP EVPN sessions among PE routers, connect the CE, and switch IP-VRF transport to SR-ISIS tunnels.

**Estimated time:** ~120 minutes

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Exercise 1.1 — Lab familiarization](#exercise-11--lab-familiarization)
4. [Exercise 1.2 — MPLS label blocks for SR](#exercise-12--mpls-label-blocks-for-sr)
5. [Exercise 1.3 — IS-IS segment routing](#exercise-13--isis-segment-routing)
6. [Exercise 1.4 — MP-BGP EVPN sessions](#exercise-14--mp-bgp-evpn-sessions)
7. [Exercise 1.5 — CE access interface](#exercise-15--ce-access-interface)
8. [Exercise 1.6 — IP-VRF over SR-ISIS tunnels](#exercise-16--ip-vrf-over-sr-isis-tunnels)
9. [Troubleshooting](#troubleshooting)
10. [What's Next?](#whats-next)

---

## Overview

In this lab you will:

- Verify the 12-router WAN topology addressing on **R1-P1**, **R5-PE1**, and **R9-CE1**
- Configure MPLS label blocks and IS-IS segment routing on R1-P1 and R5-PE1
- Configure MP-BGP EVPN on R5-PE1 toward the other PE routers
- Configure the CE access interface on R9-CE1
- Modify the preconfigured `ip-vrf-symm` service to use SR-ISIS transport tunnels

**Student routers:** R1-P1, R5-PE1, R9-CE1 (all others preconfigured)

---

## Prerequisites

- Lab 1 deployed: `./scripts/deploy-lab.sh 1`
- SSH access to `r1-p1`, `r5-pe1`, `r9-ce1`
- Familiarity with SR Linux `enter candidate` / `commit stay` workflow

---

## Exercise 1.1 — Lab familiarization

Connect to R1-P1, R5-PE1, and R9-CE1. Verify interfaces and IS-IS adjacencies.

### Verification commands

```bash
show network-instance default interfaces *
info /network-instance default protocols isis
show network-instance default protocols isis adjacency
show network-instance default route-table ipv4-unicast summary
```

### Steps

1. On each router, verify `system0.0` uses `10.10.10.x/32` where **x** is the router number.
2. Verify point-to-point links use `10.x.y.z/27` addressing (see [topology](../docs/topology.md)).
3. On **R1-P1**, verify **five** IS-IS adjacencies are up.
4. On **R5-PE1**, verify **two** IS-IS adjacencies are up (to R1-P1 and one other P router).
5. Display the IS-IS link-state database and IPv4 route table on R1-P1.

---

## Exercise 1.2 — MPLS label blocks for SR

Configure SRGB and SRLB label ranges on R1-P1 and R5-PE1.

### Configuration commands

```bash
enter candidate
/system mpls label-ranges static srgb-range-1 shared true start-label 16001 end-label 16999
/system mpls label-ranges dynamic srlb-dynamic-isis start-label 15001 end-label 15999
commit stay
```

### Verification

```bash
info from state /system mpls label-ranges
```

### Steps

1. On **R1-P1** and **R5-PE1**, configure static shared SRGB `srgb-range-1` [16001–16999].
2. On both routers, configure dynamic SRLB `srlb-dynamic-isis` [15001–15999].
3. Verify both ranges show `status ready`.

---

## Exercise 1.3 — IS-IS segment routing

Enable IS-IS to advertise segment routing information.

### Configuration commands

```bash
enter candidate
/network-instance default segment-routing mpls global-block label-range srgb-range-1
/network-instance default protocols isis dynamic-label-block srlb-dynamic-isis
/network-instance default protocols isis instance il segment-routing mpls dynamic-adjacency-sids all-interfaces true
/network-instance default protocols isis instance il interface system0.0 segment-routing mpls ipv4-node-sid index <router-number>
commit stay
```

### Verification

```bash
info from state /network-instance default segment-routing mpls sid-database
show network-instance default tunnel-table ipv4
show network-instance default route-table mpls
```

### Steps

1. Assign `srgb-range-1` to the SR global block on both routers.
2. Assign `srlb-dynamic-isis` to the IS-IS dynamic label block.
3. Enable dynamic adjacency SIDs on all IS-IS interfaces.
4. Configure a node SID on `system0.0` with index equal to the router number (1 on R1, 5 on R5).
5. Verify the SID database shows prefix-SIDs for all P/PE loopbacks.
6. On R1-P1, verify SR-ISIS tunnels to remote node SIDs and adjacency SIDs.
7. Examine IS-IS LSP TLVs for SR capabilities on R5-PE1's LSP.

---

## Exercise 1.4 — MP-BGP EVPN sessions

Configure MP-BGP for EVPN on **R5-PE1** toward R6-PE2, R7-PE3, and R8-PE4.

### Configuration commands

```bash
enter candidate
/network-instance default protocols bgp autonomous-system 65530
/network-instance default protocols bgp router-id 10.10.10.5
/network-instance default protocols bgp afi-safi evpn admin-state enable
/network-instance default protocols bgp afi-safi evpn evpn rapid-update true default-received-encapsulation mpls
/network-instance default protocols bgp route-advertisement rapid-withdrawal true
/network-instance default protocols bgp group evpn peer-as 65530
/network-instance default protocols bgp group evpn afi-safi evpn admin-state enable
/network-instance default protocols bgp group evpn transport local-address 10.10.10.5
/network-instance default protocols bgp neighbor 10.10.10.6 peer-group evpn
/network-instance default protocols bgp neighbor 10.10.10.7 peer-group evpn
/network-instance default protocols bgp neighbor 10.10.10.8 peer-group evpn
/network-instance default protocols bgp admin-state enable
commit stay
```

### Verification

```bash
show network-instance default protocols bgp neighbor
```

### Steps

1. Configure BGP AS **65530**, router-id **10.10.10.5**.
2. Enable EVPN AFI/SAFI with MPLS encapsulation and rapid-update.
3. Create BGP neighbors to **10.10.10.6**, **10.10.10.7**, **10.10.10.8** in group `evpn`.
4. Verify three established EVPN BGP sessions.

---

## Exercise 1.5 — CE access interface

Configure the access interface on **R9-CE1** toward R5-PE1.

### Configuration commands

```bash
enter candidate
/interface ethernet-1/1 vlan-tagging true
/interface ethernet-1/1 ethernet mac-address 00:00:00:99:02:01
/interface ethernet-1/1 subinterface 10 type routed
/interface ethernet-1/1 subinterface 10 admin-state enable
/interface ethernet-1/1 subinterface 10 ipv4 admin-state enable
/interface ethernet-1/1 subinterface 10 ipv4 address 192.168.1.1/24
/interface ethernet-1/1 subinterface 10 vlan encap single-tagged vlan-id 10
/network-instance default interface ethernet-1/1.10
commit stay
```

### Verification

```bash
show interface ethernet-1/1
ping 192.168.1.2 network-instance default -c 3
```

### Steps

1. On R9-CE1, configure `ethernet-1/1.10` as routed with VLAN 10 and IP **192.168.1.1/24**.
2. On R5-PE1, verify the preconfigured `ethernet-1/2.10` bridged subinterface toward CE (VLAN 10).
3. Verify interface operational state on both sides.

> CE-to-CE connectivity is not expected until EVPN services are configured in Lab 4.

---

## Exercise 1.6 — IP-VRF over SR-ISIS tunnels

Verify the preconfigured `ip-vrf-symm` on R5-PE1 uses SR-ISIS transport.

### Configuration commands

The startup config already includes SR-ISIS tunnel resolution. To configure manually:

```bash
enter candidate
/network-instance ip-vrf-symm protocols bgp-evpn bgp-instance 1 mpls next-hop-resolution allowed-tunnel-types [sr-isis]
commit stay
```

### Verification

```bash
tools oam lsp-ping sr-isis prefix-sid 10.10.10.6/32
info from state oam lsp-ping sr-isis prefix-sid 10.10.10.6/32 session-id <id>
show network-instance ip-vrf-symm route-table
ping network-instance ip-vrf-symm <remote-ip> -I 172.16.1.1
```

### Steps

1. On R5-PE1, run LSP-ping to remote PE loopbacks via SR-ISIS.
2. Verify `ip-vrf-symm` allows **sr-isis** tunnel type for next-hop resolution.
3. Verify IP-VRF routes and end-to-end ping across the IP-VRF service.

---

## Troubleshooting

**IS-IS adjacencies down**
- Check interface `admin-state` and IPv4 addressing on both ends.
- Verify matching IS-IS NET area `49.0001`.

**SR tunnels missing**
- Confirm SRGB/SRLB label ranges are `ready`.
- Verify node SID index matches router number.

**BGP EVPN sessions not established**
- Confirm router-id and transport local-address use `10.10.10.5`.
- Verify remote PE routers are reachable via IS-IS.

---

## What's Next?

Continue to **[Lab 2: TE Link Attributes](lab2-te-link-attributes.md)** — configure traffic engineering link attributes and IS-IS TE advertisement.

**[Back to lab index](README.md)**
