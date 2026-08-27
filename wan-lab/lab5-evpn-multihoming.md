# 🔗 Lab 5 — Configuration of EVPN multi-homing in ELAN

> **All-active and single-active EVPN Ethernet Segment multi-homing**

**Estimated time:** ~150 minutes

---

## 📋 Table of Contents

1. [Objective](#objective)
2. [Prerequisites](#prerequisites)
3. [Router naming reminder](#router-naming-reminder)
4. [Exercise 5.1 — Configure LAG on Access CE](#exercise-51--configure-lag-on-access-ce)
5. [Exercise 5.2 — Configure MAC-VRF on PE1](#exercise-52--configure-mac-vrf-on-pe1)
6. [Exercise 5.3 — Configure an all-active Ethernet Segment and associate LAG with MAC-VRF](#exercise-53--configure-an-all-active-ethernet-segment-and-associate-lag-with-mac-vrf)
7. [Exercise 5.4 — Explore EVPN routes used for multi-homing](#exercise-54--explore-evpn-routes-used-for-multi-homing)
8. [Exercise 5.5 — Verify default DF election algorithm](#exercise-55--verify-default-df-election-algorithm)
9. [Exercise 5.6 — Configure the preference-based DF election algorithm](#exercise-56--configure-the-preference-based-df-election-algorithm)
10. [Exercise 5.7 — Verify the MAC routes in multi-homing](#exercise-57--verify-the-mac-routes-in-multi-homing)
11. [Exercise 5.8 — Configure ECMP to enable aliasing](#exercise-58--configure-ecmp-to-enable-aliasing)
12. [Exercise 5.9 — Examine ES failure and redundancy](#exercise-59--examine-es-failure-and-redundancy)
13. [Exercise 5.10 — Configure the Ethernet segment for single-active mode](#exercise-510--configure-the-ethernet-segment-for-single-active-mode)
14. [What's Next?](#whats-next)

---

## Objective

The objective of this lab is to configure and verify EVPN multi-homing for an ELAN.

The student will focus on configuring **PE1 (R5-PE1)**, **PE3 (R7-PE3)** and **CE1 (R9-CE1)**. All other PEs and CE2 are preconfigured.

---

## Prerequisites

Load the Lab 5 start configuration via the deployment script before starting the exercises:

```bash
./scripts/deploy-lab.sh 5
```

> **Transport:** EVPN services continue to use **SR-ISIS** transport (inherited from Lab 4).

---

## Router naming reminder

| Lab guide | Workshop router | Loopback |
|-----------|-----------------|----------|
| PE1 (MH peer) | **R5-PE1** | 10.10.10.5 |
| PE2 (observer) | **R6-PE2** | 10.10.10.6 |
| PE3 (MH peer) | **R7-PE3** | 10.10.10.7 |
| CE1 | **R9-CE1** | — |
| CE2 | **R10-CE2** | — |

The lab guide uses the same loopbacks as this topology (`10.10.10.5`–`10.10.10.8`), so PE addresses in the guide outputs can be read directly.

---

## Exercise 5.1 — Configure LAG on Access CE

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

## Exercise 5.2 — Configure MAC-VRF on PE1

### Steps

1. On R5-PE1, configure **mac-vrf-10** (if not already present from Lab 4).
2. Verify bridged subinterface association with the access interface.

---

## Exercise 5.3 — Configure an all-active Ethernet Segment and associate LAG with MAC-VRF

Configure ESI-1 on **R5-PE1** and **R7-PE3**.

### Configuration commands

```bash
enter candidate
/interface ethernet-1/2 admin-state enable
/interface ethernet-1/2 ethernet aggregate-id lag1
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

## Exercise 5.4 — Explore EVPN routes used for multi-homing

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

## Exercise 5.5 — Verify default DF election algorithm

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

## Exercise 5.6 — Configure the preference-based DF election algorithm

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

## Exercise 5.7 — Verify the MAC routes in multi-homing

### Verification

```bash
show network-instance default protocols bgp routes evpn route-type 2 summary
show network-instance mac-vrf-10 bridge-table mac-table all
```

### Steps

1. Generate traffic from R9-CE1 to learn MAC addresses on remote PEs.
2. Verify RT-2 MAC routes with ESI and aliasing information.

---

## Exercise 5.8 — Configure ECMP to enable aliasing

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

## Exercise 5.9 — Examine ES failure and redundancy

### Steps

1. On R5-PE1, administratively disable `ethernet-1/2` (or LAG member).
2. On R6-PE2, verify ES destination resolution updates.
3. Re-enable the interface and verify both PEs are valid next-hops again.

---

## Exercise 5.10 — Configure the Ethernet segment for single-active mode

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
