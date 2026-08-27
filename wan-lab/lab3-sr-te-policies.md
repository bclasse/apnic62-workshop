# 🛤️ Lab 3 — Configuration of segment routing tunnels with traffic engineering (uncolored SR-MPLS TE policy)

> **Segment routing tunnels with traffic engineering constraints**

**Estimated time:** ~180 minutes

---

## 📋 Table of Contents

1. [Objective](#objective)
2. [Prerequisites](#prerequisites)
3. [Exercise 3.1 — Configure an uncolored SR-MPLS TE policy that uses IGP metrics](#exercise-31--configure-an-uncolored-sr-mpls-te-policy-that-uses-igp-metrics)
4. [Exercise 3.2 — Configure a dedicated MPLS label range for the binding SID (BSID)](#exercise-32--configure-a-dedicated-mpls-label-range-for-the-binding-sid-bsid)
5. [Exercise 3.3 — Configure an uncolored SR-MPLS TE policy that uses explicit paths](#exercise-33--configure-an-uncolored-sr-mpls-te-policy-that-uses-explicit-paths)
6. [Exercise 3.4 — Modify the TE policy to use TE metrics](#exercise-34--modify-the-te-policy-to-use-te-metrics)
7. [Exercise 3.5 — Verify label stack reduction for a TE policy](#exercise-35--verify-label-stack-reduction-for-a-te-policy)
8. [Exercise 3.6 — Configure a TE policy with excluded hops](#exercise-36--configure-a-te-policy-with-excluded-hops)
9. [Exercise 3.7 — Configure a TE policy with seamless BFD](#exercise-37--configure-a-te-policy-with-seamless-bfd)
10. [Exercise 3.8 — Configure a TE policy with a secondary path for redundancy, ensuring path diversity through SRLGs](#exercise-38--configure-a-te-policy-with-a-secondary-path-for-redundancy-ensuring-path-diversity-through-srlgs)
11. [Exercise 3.9 — Modify the IP-VRF to use TE policy transport tunnels](#exercise-39--modify-the-ip-vrf-to-use-te-policy-transport-tunnels)
12. [What's Next?](#whats-next)

---

## Objective

Students will create segment routing tunnels, also known as label switched paths, that satisfy traffic engineering constraints. Students will then modify the existing IP-VRF to have it use SR-TE transport tunnels.

In SR Linux, SR-TE LSPs are referred to as *uncolored SR-MPLS TE-policy segment lists*. A TE policy allows a set of paths to be grouped into a coherent policy supporting resiliency scenarios (a primary path with secondary and/or standby paths), including BFD for rapid failure detection and switchover. Path constraints are managed per path.

**Student routers:** R1-P1, R5-PE1, R9-CE1 (all others preconfigured)

---

## Prerequisites

Load the start configuration of this lab via the deployment script before proceeding:

```bash
./scripts/deploy-lab.sh 3
```

---

## Exercise 3.1 — Configure an uncolored SR-MPLS TE policy that uses IGP metrics

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

## Exercise 3.2 — Configure a dedicated MPLS label range for the binding SID (BSID)

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

## Exercise 3.3 — Configure an uncolored SR-MPLS TE policy that uses explicit paths

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

## Exercise 3.4 — Modify the TE policy to use TE metrics

### Steps

1. Modify the TE policy to use **TE metrics** instead of IGP metrics for path computation.
2. Verify the policy database reflects TE metric values.
3. Observe path changes when TE link attributes affect path selection.

---

## Exercise 3.5 — Verify label stack reduction for a TE policy

### Steps

1. Configure a TE policy where label stack reduction applies.
2. Verify pushed MPLS label stack on the active path using:

```bash
show network-instance default tunnel-table ipv4 <prefix> type te-policy-sr-mpls-uncolored detail
```

---

## Exercise 3.6 — Configure a TE policy with excluded hops

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

## Exercise 3.7 — Configure a TE policy with seamless BFD

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

## Exercise 3.8 — Configure a TE policy with a secondary path for redundancy, ensuring path diversity through SRLGs

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

## Exercise 3.9 — Modify the IP-VRF to use TE policy transport tunnels

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

Continue to **[Lab 4 — Configuration of EVPN ELAN](lab4-evpn-elan.md)** — deploy Layer 2 EVPN services using SR-ISIS transport.

**[Back to lab index](README.md)**
