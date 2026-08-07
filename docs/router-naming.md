# Router naming — EVPN guide to SR topology

The Nokia EVPN for WAN lab guide uses a simplified 6-router topology with different PE numbering. This workshop uses the **12-router Segment Routing WAN topology** exclusively.

Always use the SR topology names and loopbacks below when working through Labs 4 and 5.

## PE router mapping

| EVPN lab guide | Workshop router | Role | system0.0 |
|----------------|-----------------|------|-----------|
| PE1 (student PE) | **R5-PE1** | Provider edge | 10.10.10.5/32 |
| PE2 | **R6-PE2** | Provider edge | 10.10.10.6/32 |
| PE3 | **R7-PE3** | Provider edge | 10.10.10.7/32 |
| PE4 | **R8-PE4** | Provider edge | 10.10.10.8/32 |

## CE router mapping

| EVPN lab guide | Workshop router | Role |
|----------------|-----------------|------|
| CE1 / CE5 | **R9-CE1** | Customer edge |
| CE2 / CE6 | **R10-CE2** | Customer edge |

## Multi-homing (Lab 5)

| EVPN lab guide | Workshop router |
|----------------|-----------------|
| PE1 (ES peer) | **R5-PE1** (10.10.10.5) |
| PE3 (ES peer) | **R7-PE3** (10.10.10.7) |
| PE2 (observer) | **R6-PE2** (10.10.10.6) |

When the EVPN guide shows verification output with `10.10.10.1` or `10.10.10.3` as PE loopbacks, substitute **10.10.10.5** and **10.10.10.7** respectively.

## Provider core (reference)

| Router | Role | system0.0 |
|--------|------|-----------|
| R1-P1 | Provider | 10.10.10.1/32 |
| R2-P2 | Provider | 10.10.10.2/32 |
| R3-P3 | Provider | 10.10.10.3/32 |
| R4-P4 | Provider | 10.10.10.4/32 |

## Student focus routers

| Labs | Routers you configure |
|------|----------------------|
| Labs 1–3 (SR) | R1-P1, R5-PE1, R9-CE1 |
| Labs 4–5 (EVPN) | Primarily R5-PE1; R9-CE1 for access; R7-PE3 for multi-homing |

All other routers are preconfigured in the containerlab startup configs.
