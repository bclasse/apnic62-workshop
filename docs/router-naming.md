# Router naming — lab guide to containerlab nodes

The workshop lab guide presents one set of routers through two views: the **segment routing lab environment** (12 routers, Labs 1–3) and the **EVPN lab environment** (six of the same routers, Labs 4–5). PE1–PE4 in the EVPN view are the segment routing view's R5–R8 and keep their `system0.0` addresses, so the guide's loopbacks and this topology's loopbacks are identical.

Use the containerlab node names below when connecting to routers.

## PE router mapping

| Lab guide (EVPN view) | Workshop router | Role | system0.0 |
|-----------------------|-----------------|------|-----------|
| PE1 (student PE) | **R5-PE1** | Provider edge | 10.10.10.5/32 |
| PE2 | **R6-PE2** | Provider edge | 10.10.10.6/32 |
| PE3 | **R7-PE3** | Provider edge | 10.10.10.7/32 |
| PE4 | **R8-PE4** | Provider edge | 10.10.10.8/32 |

## CE router mapping

| Lab guide (EVPN view) | Workshop router | Role |
|-----------------------|-----------------|------|
| CE1 | **R9-CE1** | Customer edge |
| CE2 | **R10-CE2** | Customer edge |

## Multi-homing (Lab 5)

| Lab guide (EVPN view) | Workshop router |
|-----------------------|-----------------|
| PE1 (ES peer) | **R5-PE1** (10.10.10.5) |
| PE3 (ES peer) | **R7-PE3** (10.10.10.7) |
| PE2 (observer) | **R6-PE2** (10.10.10.6) |

The guide's verification outputs already use `10.10.10.5`–`10.10.10.8` for PE1–PE4, so they can be compared with your router output directly — no substitution needed.

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
| Labs 1–3 (segment routing view) | R1-P1, R5-PE1, R9-CE1 |
| Lab 4 (EVPN view) | R5-PE1; R9-CE1 for the access interface (Exercise 4.1) |
| Lab 5 (EVPN view) | R5-PE1, R7-PE3 (Ethernet Segment peers) and R9-CE1 (LAG) |

All other routers are preconfigured in the containerlab startup configs.
