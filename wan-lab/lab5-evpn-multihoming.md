# 🔗 Lab 5: EVPN Multi-homing ELAN

> **All-active and single-active EVPN Ethernet Segment multi-homing**

Configure LAG-based multi-homing between **R5-PE1** and **R7-PE3** toward **R9-CE1**, explore EVPN MH routes, DF election, aliasing, and failure scenarios.

**Estimated time:** ~150 minutes

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Router naming reminder](#router-naming-reminder)
3. [Exercise 5.1 — Configure LAG on access CE](#exercise-51--configure-lag-on-access-ce)
4. [Exercise 5.2 — Configure MAC-VRF on R5-PE1](#exercise-52--configure-mac-vrf-on-r5-pe1)
5. [Exercise 5.3 — All-active Ethernet Segment](#exercise-53--all-active-ethernet-segment)
6. [Exercise 5.4 — EVPN routes for multi-homing](#exercise-54--evpn-routes-for-multi-homing)
7. [Exercise 5.5 — Default DF election](#exercise-55--default-df-election)
8. [Exercise 5.6 — Preference-based DF election](#exercise-56--preference-based-df-election)
9. [Exercise 5.7 — MAC routes in multi-homing](#exercise-57--mac-routes-in-multi-homing)
10. [Exercise 5.8 — ECMP aliasing](#exercise-58--ecmp-aliasing)
11. [Exercise 5.9 — ES failure and redundancy](#exercise-59--es-failure-and-redundancy)
12. [Exercise 5.10 — Single-active mode](#exercise-510--single-active-mode)
13. [What's Next?](#whats-next)

---

## Overview

Deploy Lab 5 before starting:

```bash
./scripts/deploy-lab.sh 5
```

**Student routers:** R5-PE1, R7-PE3, R9-CE1 | **Observer:** R6-PE2

> **Transport:** EVPN services continue to use **SR-ISIS** transport (inherited from Lab 4).

---

## Router naming reminder

| EVPN guide | Workshop router | Loopback |
|------------|-------------------|----------|
| PE1 (MH peer) | **R5-PE1** | 10.10.10.5 |
| PE2 (observer) | **R6-PE2** | 10.10.10.6 |
| PE3 (MH peer) | **R7-PE3** | 10.10.10.7 |
| CE1 | **R9-CE1** | — |

When the EVPN guide references `10.10.10.1` / `10.10.10.3`, use **10.10.10.5** / **10.10.10.7**.

---

## Exercise 5.1 — Configure LAG on access CE

Configure LAG on **R9-CE1** toward R5-PE1 and R7-PE3.

### Configuration commands (R9-CE1)

```bash
enter candidate
/interface lag1 admin-state enable
/interface lag1 lag lag-type lacp
/interface lag1 lag lacp interval FAST
/interface lag1 lag lacp admin-key 11
/interface lag1 lag lacp system-id-mac 00:00:00:00:01:03
/interface lag1 lag lacp system-priority 11
/interface lag1 subinterface 10 type routed
/interface lag1 subinterface 10 admin-state enable
/interface lag1 subinterface 10 ipv4 admin-state enable
/interface lag1 subinterface 10 ipv4 address 192.168.1.1/24
/interface lag1 subinterface 10 vlan encap single-tagged vlan-id 10
/interface ethernet-1/1 ethernet aggregate-id lag1
/interface ethernet-1/2 ethernet aggregate-id lag1
/network-instance default interface lag1.10
commit stay
```

### Steps

1. Configure **lag1** with LACP on R9-CE1.
2. Add `ethernet-1/1` and `ethernet-1/2` as LAG members.
3. Verify LAG is operationally up on CE and both PEs.

---

## Exercise 5.2 — Configure MAC-VRF on R5-PE1

### Steps

1. On R5-PE1, configure **mac-vrf-10** (if not already present from Lab 4).
2. Verify bridged subinterface association with the access interface.

---

## Exercise 5.3 — All-active Ethernet Segment

Configure ESI-1 on **R5-PE1** and **R7-PE3**.

### Configuration commands

```bash
enter candidate
/interface ethernet-1/5 admin-state enable
/interface ethernet-1/5 ethernet aggregate-id lag1
/interface lag1 admin-state enable
/interface lag1 subinterface 10 type bridged
/interface lag1 subinterface 10 admin-state enable
/interface lag1 subinterface 10 vlan encap single-tagged vlan-id 10
/network-instance mac-vrf-10 interface lag1.10
/system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ESI-1 esi 01:00:00:00:00:01:00:00:00:01
/system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ESI-1 multi-homing-mode all-active
/system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ESI-1 interface lag1
/system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ESI-1 admin-state enable
/system network-instance protocols bgp-vpn bgp-instance 1
commit stay
```

> On R7-PE3, use `ethernet-1/3` as the LAG member interface toward R9-CE1.

### Verification

```bash
show system network-instance ethernet-segments ESI-1 detail
show interface lag1
```

---

## Exercise 5.4 — EVPN routes for multi-homing

### Verification (on R6-PE2)

```bash
show network-instance default protocols bgp routes evpn route-type 1 ethernet-tag-id 4294967295 summary
show network-instance default protocols bgp routes evpn route-type 4 summary
show network-instance mac-vrf-10 protocols bgp-vpn bgp-instance 1
```

### Steps

1. List A-D per-ES routes (Tag-ID 4294967295) from R5-PE1 and R7-PE3.
2. List ES routes (RT-4) — R5 and R7 should each advertise one ES route for ESI-1.
3. Examine RD/RT values on MAC-VRF bgp-vpn instance.

---

## Exercise 5.5 — Default DF election

### Verification

```bash
show network-instance default protocols bgp routes evpn route-type 4 detail
show system network-instance ethernet-segments ESI-1 detail
```

### Steps

1. Examine DF election extended community (DF-Type: Auto) in ES routes.
2. Display DF candidate list for `mac-vrf-10` on R5-PE1.
3. Verify modulo-based DF election between R5-PE1 and R7-PE3.

---

## Exercise 5.6 — Preference-based DF election

### Configuration commands

```bash
enter candidate
/system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ESI-1 df-election algorithm type preference
/system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ESI-1 df-election algorithm preference-alg preference-value 500
commit stay
```

### Steps

1. On R5-PE1, set preference DF algorithm with preference **500**.
2. On R7-PE3, set preference **600** (higher wins).
3. Verify DF re-election and updated ES route communities.

---

## Exercise 5.7 — MAC routes in multi-homing

### Verification

```bash
show network-instance default protocols bgp routes evpn route-type 2 summary
show network-instance mac-vrf-10 bridge-table mac-table all
```

### Steps

1. Generate traffic from R9-CE1 to learn MAC addresses on remote PEs.
2. Verify RT-2 MAC routes with ESI and aliasing information.

---

## Exercise 5.8 — ECMP aliasing

### Configuration commands

```bash
enter candidate
/network-instance mac-vrf-10 protocols bgp-evpn bgp-instance 1 ecmp max-paths 2
commit stay
```

### Steps

1. Enable ECMP on MAC-VRF for aliasing.
2. Verify multiple next-hops for ES destinations on R6-PE2.

---

## Exercise 5.9 — ES failure and redundancy

### Steps

1. On R5-PE1, administratively disable `ethernet-1/5` (or LAG member).
2. On R6-PE2, verify ES destination resolution updates.
3. Re-enable the interface and verify both PEs are valid next-hops again.

---

## Exercise 5.10 — Single-active mode

### Configuration commands

```bash
enter candidate
/system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ESI-1 multi-homing-mode single-active
commit stay
```

### Verification

```bash
show system network-instance ethernet-segments ESI-1 detail
show network-instance mac-vrf-10 interfaces lag1.10
show network-instance default protocols bgp routes evpn route-type 1 summary
```

### Steps

1. On R5-PE1 and R7-PE3, change ESI-1 to **single-active** mode.
2. Identify the DF PE for `mac-vrf-10`.
3. On DF PE: verify LAG and MAC-VRF are up.
4. On non-DF PE: verify LAG oper-down reason `evpn-mh-standby`.
5. On R6-PE2, verify A-D routes show single-active ES redundancy mode.

---

## What's Next?

Congratulations — you have completed all five APNIC62 WAN labs!

**[Back to lab index](README.md)**
