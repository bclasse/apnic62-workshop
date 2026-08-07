# 🛤️ Lab 3: Uncolored SR-MPLS TE Policies

> **Segment routing tunnels with traffic engineering constraints**

Create SR-MPLS TE policies with IGP/TE metrics, explicit paths, excluded hops, seamless BFD, SRLG-diverse secondary paths, and switch IP-VRF transport to TE policies.

**Estimated time:** ~180 minutes

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Exercise 3.1 — TE policy using IGP metrics](#exercise-31--te-policy-using-igp-metrics)
3. [Exercise 3.2 — BSID label range](#exercise-32--bsid-label-range)
4. [Exercise 3.3 — Explicit paths](#exercise-33--explicit-paths)
5. [Exercise 3.4 — TE metrics](#exercise-34--te-metrics)
6. [Exercise 3.5 — Label stack reduction](#exercise-35--label-stack-reduction)
7. [Exercise 3.6 — Excluded hops](#exercise-36--excluded-hops)
8. [Exercise 3.7 — Seamless BFD](#exercise-37--seamless-bfd)
9. [Exercise 3.8 — Secondary path with SRLG diversity](#exercise-38--secondary-path-with-srlg-diversity)
10. [Exercise 3.9 — IP-VRF over TE policy transport](#exercise-39--ip-vrf-over-te-policy-transport)
11. [What's Next?](#whats-next)

---

## Overview

Deploy Lab 3 before starting:

```bash
./scripts/deploy-lab.sh 3
```

**Student routers:** R1-P1, R5-PE1, R9-CE1

---

## Exercise 3.1 — TE policy using IGP metrics

### Configuration commands

```bash
enter candidate
/network-instance default traffic-engineering-policies policy toPE2-loose policy-type sr-mpls-uncolored admin-state enable endpoint 10.10.10.6
/network-instance default traffic-engineering-policies policy toPE2-loose segment-list 1 admin-state enable segment-list-type primary
commit stay
```

### Verification

```bash
info from state /network-instance default traffic-engineering-policies policy-database
```

### Steps

1. On R5-PE1 and R1-P1, note IS-IS metric **50** on `ethernet-1/5.0` (higher than default 10).
2. On **R5-PE1**, create TE policy **toPE2-loose** terminating at **10.10.10.6** (R6-PE2) with a loose primary path.
3. Verify policy database shows oper-state `up` and IGP-based metric.
4. Disable the policy and verify it goes down.

---

## Exercise 3.2 — BSID label range

### Configuration commands

```bash
enter candidate
/system mpls label-ranges static srl-static-bsid shared false start-label 12001 end-label 13999
/network-instance default traffic-engineering-policies binding-sid static-label-block srl-static-bsid
commit stay
```

### Steps

1. On R5-PE1, configure static BSID block **srl-static-bsid** [12001–13999].
2. Assign it to TE policy binding SIDs.
3. Verify label block owner is `sr-policy`.

---

## Exercise 3.3 — Explicit paths

### Configuration commands

```bash
enter candidate
/network-instance default traffic-engineering-policies policy <name> segment-list 1 explicit-path hop <n> ip-address <ip> loose false
commit stay
```

### Steps

1. Create a TE policy with **explicit hops** to R6-PE2 via a constrained path.
2. Verify computed segments in the policy database match explicit hops.
3. Compare path with the loose IGP-metric policy from Exercise 3.1.

---

## Exercise 3.4 — TE metrics

### Steps

1. Modify the TE policy to use **TE metrics** instead of IGP metrics for path computation.
2. Verify the policy database reflects TE metric values.
3. Observe path changes when TE link attributes affect path selection.

---

## Exercise 3.5 — Label stack reduction

### Steps

1. Configure a TE policy where label stack reduction applies.
2. Verify pushed MPLS label stack on the active path using:

```bash
show network-instance default tunnel-table ipv4 <prefix> type te-policy-sr-mpls-uncolored detail
```

---

## Exercise 3.6 — Excluded hops

### Configuration commands

```bash
enter candidate
/network-instance default traffic-engineering-policies policy <name> segment-list 1 exclude-hop <n> ip-address <ip>
commit stay
```

### Steps

1. Create a TE policy with **excluded hops** to avoid a specific node or link.
2. Verify the computed path does not traverse excluded addresses.

---

## Exercise 3.7 — Seamless BFD

### Configuration commands

```bash
enter candidate
/network-instance default traffic-engineering-policies policy <name> bfd-liveness seamless-bfd admin-state enable
commit stay
```

### Steps

1. Enable **seamless BFD** on a TE policy.
2. Verify BFD session state and fast failover on link failure (if simulating failure in lab).

---

## Exercise 3.8 — Secondary path with SRLG diversity

### Configuration commands

```bash
enter candidate
/network-instance default traffic-engineering-policies policy <name> segment-list 2 admin-state enable segment-list-type secondary
/network-instance default traffic-engineering-policies policy <name> segment-list 2 constraints srlg-diversity true
commit stay
```

### Steps

1. Add a **secondary** segment list to the TE policy.
2. Enable **SRLG diversity** between primary and secondary paths.
3. Verify both paths are computed and SRLG constraints are respected.

---

## Exercise 3.9 — IP-VRF over TE policy transport

### Configuration commands

```bash
enter candidate
/network-instance ip-vrf-symm protocols bgp-evpn bgp-instance 1 mpls next-hop-resolution allowed-tunnel-types [te-policy-sr-mpls-uncolored]
commit stay
```

### Verification

```bash
show network-instance ip-vrf-symm route-table
ping network-instance ip-vrf-symm <remote-ip> -I 172.16.1.1
```

### Steps

1. On R5-PE1, modify `ip-vrf-symm` to use **te-policy-sr-mpls-uncolored** transport.
2. Verify IP-VRF routes resolve via TE policy tunnels.
3. Test end-to-end connectivity across the IP-VRF service.

---

## What's Next?

Continue to **[Lab 4: EVPN ELAN](lab4-evpn-elan.md)** — deploy Layer 2 EVPN services using SR-ISIS transport.

**[Back to lab index](README.md)**
