# 🔧 Lab 1 — Configuration of IS-IS to support Segment Routing and MP-BGP sessions for EVPN

> **Foundation: SR underlay and EVPN control plane**

**Estimated time:** ~120 minutes

---

## 📋 Table of Contents

1. [Objective](#objective)
2. [Prerequisites](#prerequisites)
3. [Exercise 1.1 — Familiarization with the lab setup](#exercise-11--familiarization-with-the-lab-setup)
4. [Exercise 1.2 — Configure MPLS label blocks for segment routing](#exercise-12--configure-mpls-label-blocks-for-segment-routing)
5. [Exercise 1.3 — Configure IS-IS to support segment routing](#exercise-13--configure-is-is-to-support-segment-routing)
6. [Exercise 1.4 — Configure MP-BGP for EVPN as the PE-to-PE protocol](#exercise-14--configure-mp-bgp-for-evpn-as-the-pe-to-pe-protocol)
7. [Exercise 1.5 — Modify an EVPN-MPLS IP-VRF to use IS-IS segment routing transport tunnels](#exercise-15--modify-an-evpn-mpls-ip-vrf-to-use-is-is-segment-routing-transport-tunnels)
8. [Troubleshooting](#troubleshooting)
9. [What's Next?](#whats-next)

---

## Objective

Students will log in to their assigned routers, familiarize themselves with the addressing scheme being used in the lab, and proceed to configure IS-IS to support segment routing. Lastly, students will modify the existing IP virtual routing function (VRF) to have it use segment routing transport tunnels.

**Student routers:** R1-P1, R5-PE1, R9-CE1 (all others preconfigured)

---

## Prerequisites

Load the start configuration of this lab via the deployment script before proceeding:

```bash
./scripts/deploy-lab.sh 1
```

- SSH access to `r1-p1`, `r5-pe1`, `r9-ce1`
- Familiarity with the SR Linux `enter candidate` / `commit stay` workflow

---

## Exercise 1.1 — Familiarization with the lab setup

Connect to R1-P1, R5-PE1, and R9-CE1. Use the `show` and `info` commands to verify that the system and physical interfaces have been properly configured and are operational, and that IS-IS is distributing routing information among the P and PE routers.

### Verification commands

```bash
show /network-instance default interfaces *
info /network-instance default protocols isis
show /network-instance default protocols isis adjacency
show /network-instance default protocols isis database
show /network-instance default ipv4 route
```

### Steps

1. Connect to the three routers **R1-P1**, **R5-PE1** and **R9-CE1**.
2. On each router, display the interfaces in `network-instance default`:
   - a. Verify `system0.0` uses `10.10.10.x/32`, where **x** is the router number (R1-P1 → `10.10.10.1/32`).
   - b. Verify the point-to-point interfaces use `10.x.y.z/27`, where **x** is the lower router number, **y** the higher and **z** this router's number (the R2–R6 link is `10.2.6.2/27` on R2 and `10.2.6.6/27` on R6). There should be **five** physical interfaces on R1-P1, **two** on R5-PE1 and **one** on R9-CE1, all operational.
3. On **R1-P1**, verify **five** IS-IS adjacencies are up.
4. On **R5-PE1**, verify **two** IS-IS adjacencies are up (to R1-P1 and R2-P2).
5. Display the IS-IS link-state database and the IPv4 route table on R1-P1.

See [topology and addressing](../docs/topology.md) for the full address plan.

---

## Exercise 1.2 — Configure MPLS label blocks for segment routing

Configure two MPLS label blocks on R1-P1 and R5-PE1: the segment routing global block (SRGB) for global segments such as prefix and node SIDs, and the segment routing label block (SRLB) for local segments such as adjacency SIDs. SR-MPLS is supported only on the default network-instance.

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

1. On **R1-P1** and **R5-PE1**, configure a **static**, **shared** SRGB range named `srgb-range-1` [16001–16999].
2. On both routers, configure a **dynamic** SRLB range named `srlb-dynamic-isis` [15001–15999].
3. Verify both ranges show `status ready`.

> **Note:** the output on R5-PE1 displays additional ranges required for other applications, such as EVPN and network-instance services. Those ranges are preconfigured — Lab 4 and Lab 5 rely on them.

---

## Exercise 1.3 — Configure IS-IS to support segment routing

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
4. Configure a node SID on `system0.0` with index equal to the router number (1 on R1-P1, 5 on R5-PE1).
5. Verify the SID database shows prefix-SIDs for all P/PE loopbacks.
6. On R1-P1, verify SR-ISIS tunnels to remote node SIDs and adjacency SIDs.
7. Examine the IS-IS LSP TLVs for SR capabilities in R5-PE1's LSP.

---

## Exercise 1.4 — Configure MP-BGP for EVPN as the PE-to-PE protocol

Configure MP-BGP sessions that support the exchange of EVPN routes between provider core PE routers. The student configures **R5-PE1**; the other PE routers are preconfigured.

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

1. Enter configuration mode with `enter candidate`.
2. Configure MP-BGP sessions to all the other PE routers: autonomous system **65530**, router ID = `system0.0` address (**10.10.10.5**), peer AS **65530**, transport local address = `system0.0`, `afi-safi evpn`, default received encapsulation **mpls**.
3. Enable **rapid-update** for the EVPN family so EVPN routes are transmitted immediately to BGP peers.
4. Enable **rapid-withdrawal** for BGP route advertisement so withdrawals are sent immediately.
5. Enable the BGP protocol and `commit stay`.
6. Verify R5-PE1 has established **three** MP-BGP EVPN sessions — to **10.10.10.6**, **10.10.10.7** and **10.10.10.8**.

---

## Exercise 1.5 — Modify an EVPN-MPLS IP-VRF to use IS-IS segment routing transport tunnels

Modify the preconfigured EVPN-MPLS L3 service on R5-PE1 to use IS-IS segment routing transport tunnels.

### Configuration commands

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
2. Set `allowed-tunnel-types [sr-isis]` for next-hop resolution on `ip-vrf-symm`.
3. Verify the IP-VRF routes and end-to-end ping across the IP-VRF service.

---

## Troubleshooting

**IS-IS adjacencies down**

- Check interface `admin-state` and IPv4 addressing on both ends.
- Verify matching IS-IS NET area `49.0001`.

**SR tunnels missing**

- Confirm SRGB/SRLB label ranges are `ready`.
- Verify the node SID index matches the router number.

**BGP EVPN sessions not established**

- Confirm router-id and transport local-address use `10.10.10.5`.
- Verify remote PE routers are reachable via IS-IS.

---

## What's Next?

Continue to **[Lab 2 — Configuration and advertisement of traffic engineering link attributes](lab2-te-link-attributes.md)**.

**[Back to lab index](README.md)**
