# 🔀 Lab 4: EVPN ELAN

> **Layer 2 EVPN ELAN with SR-ISIS transport**

Configure EVPN-MPLS MAC-VRF services using SR-ISIS transport tunnels. **This workshop does not use LDP.**

**Estimated time:** ~90 minutes

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Router naming reminder](#router-naming-reminder)
3. [Exercise 4.1 — Configure label ranges](#exercise-41--configure-label-ranges)
4. [Exercise 4.2 — Verify SR-ISIS transport tunnels](#exercise-42--verify-sr-isis-transport-tunnels)
5. [Exercise 4.3 — Configure EVPN-MPLS MAC-VRF](#exercise-43--configure-evpn-mpls-mac-vrf)
6. [Exercise 4.4 — Enable proxy-ARP](#exercise-44--enable-proxy-arp)
7. [Troubleshooting](#troubleshooting)
8. [What's Next?](#whats-next)

---

## Overview

Deploy Lab 4 before starting:

```bash
./scripts/deploy-lab.sh 4
```

**Student router:** R5-PE1 (other PEs and CEs preconfigured)

> **Transport note:** The Nokia EVPN lab guide uses LDP. This workshop uses **SR-ISIS** exclusively. Exercise 4.2 replaces the LDP configuration exercise from the source material.

See [router naming](../docs/router-naming.md) for EVPN guide → SR topology mapping.

---

## Router naming reminder

| EVPN guide | Workshop router | Loopback |
|------------|-------------------|----------|
| PE1 | **R5-PE1** | 10.10.10.5 |
| PE2 | **R6-PE2** | 10.10.10.6 |
| PE3 | **R7-PE3** | 10.10.10.7 |
| PE4 | **R8-PE4** | 10.10.10.8 |
| CE1 | **R9-CE1** | — |

---

## Exercise 4.1 — Configure label ranges

Configure dynamic label ranges for EVPN services on **R5-PE1**.

### Configuration commands

```bash
enter candidate
/system mpls label-ranges dynamic service-labels start-label 900000 end-label 901000
/system mpls label-ranges dynamic evpn-labels start-label 111001 end-label 112000
/system mpls services network-instance dynamic-label-block service-labels
/system mpls services evpn dynamic-label-block evpn-labels
commit stay
```

### Verification

```bash
info from state /system mpls label-ranges
```

### Steps

1. Configure **service-labels** [900000–901000] and **evpn-labels** [111001–112000].
2. Assign `service-labels` to the network-instance manager.
3. Assign `evpn-labels` to the EVPN manager.
4. Verify both ranges show `status ready` with owners `network-instance` and `evpn`.

> **Not configured:** `ldp-labels` — LDP is not used in this workshop.

---

## Exercise 4.2 — Verify SR-ISIS transport tunnels

Replace the EVPN guide's LDP exercise with SR-ISIS tunnel verification.

### Verification commands

```bash
show network-instance default tunnel-table ipv4 type sr-isis
show network-instance default protocols isis adjacency
info from state /network-instance default segment-routing mpls sid-database
```

### Steps

1. On R5-PE1, verify IS-IS adjacencies to other PE routers are up.
2. Display SR-ISIS tunnels to **10.10.10.6**, **10.10.10.7**, and **10.10.10.8**.
3. Confirm tunnel type is **sr-isis** with valid FIB status.
4. Verify at least three SR-ISIS tunnels to remote PE loopbacks exist.

---

## Exercise 4.3 — Configure EVPN-MPLS MAC-VRF

### Configuration commands

```bash
enter candidate
/network-instance mac-vrf-10 type mac-vrf admin-state enable
/network-instance mac-vrf-10 interface ethernet-1/5.10
/network-instance mac-vrf-10 protocols bgp-evpn bgp-instance 1 admin-state enable
/network-instance mac-vrf-10 protocols bgp-evpn bgp-instance 1 encapsulation-type mpls
/network-instance mac-vrf-10 protocols bgp-evpn bgp-instance 1 evi 10
/network-instance mac-vrf-10 protocols bgp-evpn bgp-instance 1 mpls next-hop-resolution allowed-tunnel-types [sr-isis]
commit stay
```

### Verification

```bash
show network-instance mac-vrf-10 summary
show network-instance default protocols bgp routes evpn route-type 3 summary
show network-instance default protocols bgp routes evpn route-type 2 summary
ping 192.168.1.2 network-instance mac-vrf-10 -c 3
```

### Steps

1. Create MAC-VRF **mac-vrf-10** with EVI **10** on R5-PE1.
2. Attach `ethernet-1/5.10` (preconfigured bridged subinterface toward R9-CE1).
3. Set transport to **sr-isis** (not LDP).
4. Verify MAC-VRF is operationally up.
5. Examine IMET routes (RT-3) from R6-PE2, R7-PE3, R8-PE4.
6. Ping from R9-CE1 (192.168.1.1) to R10-CE2 (192.168.1.2) once remote PE MAC-VRF is active.

---

## Exercise 4.4 — Enable proxy-ARP

### Configuration commands

```bash
enter candidate
/network-instance mac-vrf-10 proxy-arp admin-state enable
commit stay
```

### Verification

```bash
show network-instance mac-vrf-10 proxy-arp
show network-instance mac-vrf-10 bridge-table mac-table all
```

### Steps

1. Enable **proxy-ARP** on `mac-vrf-10`.
2. From R9-CE1, ping hosts in the same subnet on other PEs.
3. Verify MAC learning and proxy-ARP operation in the bridge table.

---

## Troubleshooting

**No IMET routes from remote PEs**
- Verify MP-BGP EVPN sessions are established on all PE routers.
- Repeat ping to refresh EVPN routes (RT-2 idle timeout ~300s).

**MAC-VRF ping fails**
- Confirm SR-ISIS tunnels to remote PE loopbacks are active.
- Verify `allowed-tunnel-types [sr-isis]` on MAC-VRF bgp-evpn instance.

---

## What's Next?

Continue to **[Lab 5: EVPN Multi-homing ELAN](lab5-evpn-multihoming.md)**.

**[Back to lab index](README.md)**
