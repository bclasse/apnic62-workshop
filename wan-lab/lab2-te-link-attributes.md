# 📡 Lab 2 — Configuration and advertisement of traffic engineering link attributes

> **Traffic engineering link attributes and IS-IS TE advertisement**

**Estimated time:** ~45 minutes

---

## 📋 Table of Contents

1. [Objective](#objective)
2. [Prerequisites](#prerequisites)
3. [Exercise 2.1 — Configure traffic engineering link attributes](#exercise-21--configure-traffic-engineering-link-attributes)
4. [Exercise 2.2 — Add interfaces to the traffic engineering contexts](#exercise-22--add-interfaces-to-the-traffic-engineering-contexts)
5. [Exercise 2.3 — Enable IS-IS to advertise traffic engineering information](#exercise-23--enable-is-is-to-advertise-traffic-engineering-information)
6. [Troubleshooting](#troubleshooting)
7. [What's Next?](#whats-next)

---

## Objective

The student will configure traffic engineering link attributes, such as admin groups and shared-risk link groups (SRLGs), associate the attributes with the different interfaces, and configure the routing protocol to advertise the additional link information.

**Student routers:** R1-P1, R5-PE1, R9-CE1 (all others preconfigured)

---

## Prerequisites

Load the start configuration of this lab via the deployment script before proceeding:

```bash
./scripts/deploy-lab.sh 2
```

- Lab 1 completed (SR-ISIS operational on the P/PE routers)

---

## Exercise 2.1 — Configure traffic engineering link attributes

Create link attributes, such as admin groups and shared-risk link groups, that will later be associated with TE interfaces.

### Configuration commands

```bash
enter candidate
/network-instance default traffic-engineering ipv4-te-router-id <system0-ip>
/network-instance default traffic-engineering admin-groups group RED bit-position 1
/network-instance default traffic-engineering shared-risk-link-groups group SRLG-1 value 1
commit stay
```

### Verification

```bash
info from state /network-instance default traffic-engineering
```

### Steps

1. On **R1-P1**, set TE router ID to **10.10.10.1**.
2. On **R5-PE1**, set TE router ID to **10.10.10.5**.
3. On both routers, create admin group **RED** (bit-position 1) and SRLG **SRLG-1** (value 1).
4. Verify TE configuration with `info from state`.

---

## Exercise 2.2 — Add interfaces to the traffic engineering contexts

### Configuration commands

```bash
enter candidate
/network-instance default traffic-engineering interface ethernet-1/<n>.0 admin-group [ RED ]
/network-instance default traffic-engineering interface ethernet-1/<n>.0 srlg-membership [ SRLG-1 ]
commit stay
```

### Steps

1. On both routers, add **all physical interfaces** to the TE context.
2. On **R1-P1**, assign **RED** admin group to interfaces toward R5-PE1 and R4-P4.
3. On **R5-PE1**, assign **RED** to the interface toward R1-P1.
4. On **R1-P1**, assign **SRLG-1** to interfaces toward R5-PE1 and R3-P3.
5. On **R5-PE1**, assign **SRLG-1** to the interface toward R1-P1.
6. Verify with:

```bash
info /network-instance default traffic-engineering interface *
```

---

## Exercise 2.3 — Enable IS-IS to advertise traffic engineering information

### Configuration commands

```bash
enter candidate
/network-instance default protocols isis instance il te-database-install
/network-instance default protocols isis instance il traffic-engineering advertisement true
commit stay
```

### Verification

```bash
info from state /network-instance default protocols isis instance il level 2 link-state-database lsp <lsp-id> tlvs tlv ipv4-srlg
info from state /network-instance default protocols isis instance il level 2 link-state-database lsp 0005.0005.0005.00-00 tlvs tlv extended-is-reachability extended-is-reachability neighbors neighbor 0001.0001.0001 instances instance 0 subtlvs
```

### Steps

1. On R1-P1 and R5-PE1, install IS-IS topology into the TE database.
2. Enable IS-IS TE advertisement (application-specific / SR-policy relevant).
3. On R1-P1, verify SRLG and admin-group sub-TLVs in R5-PE1's LSP for the R1-P1 neighbor.

---

## Troubleshooting

**TE attributes not in IS-IS LSP**
- Confirm `te-database-install` and `traffic-engineering advertisement` are enabled.
- Allow a few seconds for LSP refresh after commit.

---

## What's Next?

Continue to **[Lab 3 — Configuration of segment routing tunnels with traffic engineering (uncolored SR-MPLS TE policy)](lab3-sr-te-policies.md)**.

**[Back to lab index](README.md)**
