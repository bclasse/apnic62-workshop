# 🔀 Lab 4 — Configuration of EVPN ELAN

> **Layer 2 EVPN ELAN with SR-ISIS transport**

**Estimated time:** ~90 minutes

---

## 📋 Table of Contents

1. [Objective](#objective)
2. [Prerequisites](#prerequisites)
3. [Router naming reminder](#router-naming-reminder)
4. [Exercise 4.1 — Configure CE1 Interface](#exercise-41--configure-ce1-interface)
5. [Exercise 4.2 — Configure EVPN-MPLS MAC-VRF](#exercise-42--configure-evpn-mpls-mac-vrf)
6. [Exercise 4.3 — Enable proxy-ARP for MAC-VRF](#exercise-43--enable-proxy-arp-for-mac-vrf)
7. [Troubleshooting](#troubleshooting)
8. [What's Next?](#whats-next)

---

## Objective

The objective of this lab is to configure a Layer 2 EVPN ELAN on the PE routers. BGP-EVPN is used in the control plane, and MPLS is used for data encapsulation.

The student will focus on configuring **PE1 (R5-PE1)**. All other PEs and CEs are preconfigured unless otherwise specified.

---

## Prerequisites

Load the Lab 4 start configuration via the deployment script before starting the exercises:

```bash
./scripts/deploy-lab.sh 4
```

**Student routers:** R5-PE1 and R9-CE1 (other PEs and CEs preconfigured)

> **Transport:** this workshop uses **SR-ISIS** as the sole MPLS transport — LDP is not used anywhere in the guide.

The start configuration already provisions the MPLS label ranges the EVPN services need on R5-PE1 (`service-labels` [900000–901000] for the network-instance manager, `evpn-labels` [111001–112000] for the EVPN manager) and the SR-ISIS transport tunnels built in Labs 1–3. To confirm them before you begin:

```bash
info from state /system mpls label-ranges
show network-instance default tunnel-table ipv4 type sr-isis
```

Expect both ranges at `status ready` and SR-ISIS tunnels to **10.10.10.6**, **10.10.10.7** and **10.10.10.8**.

See [router naming](../docs/router-naming.md) for the guide-to-topology mapping.

---

## Router naming reminder

| Lab guide | Workshop router | Loopback |
|-----------|-----------------|----------|
| PE1 | **R5-PE1** | 10.10.10.5 |
| PE2 | **R6-PE2** | 10.10.10.6 |
| PE3 | **R7-PE3** | 10.10.10.7 |
| PE4 | **R8-PE4** | 10.10.10.8 |
| CE1 | **R9-CE1** | — |
| CE2 | **R10-CE2** | — |

---

## Exercise 4.1 — Configure CE1 Interface

Set up the connection between **PE1 (R5-PE1)** and **CE1 (R9-CE1)**.

### Configuration commands

```bash
enter candidate
/interface ethernet-1/2 admin-state enable
/interface ethernet-1/2 vlan-tagging true
/interface ethernet-1/2 ethernet mac-address 00:00:00:99:02:01
/interface ethernet-1/2 subinterface 10 type routed
/interface ethernet-1/2 subinterface 10 admin-state enable
/interface ethernet-1/2 subinterface 10 ipv4 admin-state enable
/interface ethernet-1/2 subinterface 10 ipv4 address 192.168.1.1/24
/interface ethernet-1/2 subinterface 10 vlan encap single-tagged vlan-id 10
/network-instance default interface ethernet-1/2.10
commit stay
```

### Verification commands

```bash
ping <ip-address> network-instance default
/show interface ethernet-1/2
/show network-instance default interface | grep "192.168.1" -B 8
```

### Steps

1. On **CE1 (R9-CE1)**, configure `ethernet-1/2` toward PE1:
   - a. Set `vlan-tagging` to **true**.
   - b. Set the interface MAC address to **00:00:00:99:02:01**. The MAC follows the format `00:00:00:yy:0w:0x`, where **yy** = 99 for CE1/CE2 and 00 for PE1–PE4, **w** = port number, and **x** = 1 for CE1/PE1 and 2 for CE2/PE2.
2. Configure subinterface **10** on `ethernet-1/2` as a **routed** interface with IP **192.168.1.1/24** and VLAN ID **10**.
3. Add the subinterface to `network-instance default`.
4. On **PE1 (R5-PE1)**, verify the preconfigured `ethernet-1/2`. Its subinterface VLAN ID should match CE1's, with `type bridged` and MAC `00:00:00:00:02:01`.
5. Use the show commands to verify the status and configuration of the interface on both sides.

> **Note:** at this point CE1 cannot ping CE2 — no EVPN services have been configured in the network yet.

---

## Exercise 4.2 — Configure EVPN-MPLS MAC-VRF

Configure an EVPN ELAN service that spans all PEs, using EVPN in the control plane and MPLS for data encapsulation.

### Configuration commands

```bash
enter candidate
/network-instance mac-vrf-10 type mac-vrf
/network-instance mac-vrf-10 admin-state enable
/network-instance mac-vrf-10 interface ethernet-1/2.10
/network-instance mac-vrf-10 protocols bgp-evpn bgp-instance 1 admin-state enable
/network-instance mac-vrf-10 protocols bgp-evpn bgp-instance 1 encapsulation-type mpls
/network-instance mac-vrf-10 protocols bgp-evpn bgp-instance 1 evi 10
/network-instance mac-vrf-10 protocols bgp-evpn bgp-instance 1 mpls next-hop-resolution allowed-tunnel-types [sr-isis]
/network-instance mac-vrf-10 protocols bgp-vpn bgp-instance 1
commit stay
```

### Verification commands

```bash
/show network-instance mac-vrf-10 summary
/show network-instance mac-vrf-10 bridge-table mac-table all
/show network-instance default protocols bgp routes evpn route-type 3 summary
/show network-instance default protocols bgp routes evpn route-type 2 summary
/show network-instance default protocols bgp routes evpn route-type 2 mac-address <mac-address> detail
/info from state network-instance mac-vrf-10 protocols bgp-evpn bgp-instance 1 mpls bridge-table multicast-destinations
ping 192.168.1.2 network-instance default
```

### Steps

1. On PE1, create an EVPN MAC-VRF network instance:
   - a. Network-instance name: **mac-vrf-10**
   - b. Type: **mac-vrf**
   - c. Interface: **ethernet-1/2.10**
   - d. EVI: **10**
   - e. Encapsulation-type: **MPLS**
   - f. Transport: **SR-ISIS tunnels**
   - g. RD and RT: use the default values, auto-derived from the EVI
2. Verify the status of the newly created `mac-vrf-10`.
3. Examine the EVPN IMET routes (**RT-3**) received from the remote PEs — one entry per remote PE participating in the EVI, each giving the egress MPLS tunnel endpoint, the MPLS service label and the SR-ISIS tunnel used for BUM traffic.
4. From **CE1 (192.168.1.1)**, ping **CE2 (192.168.1.2)** using `network-instance default`; the ping should succeed.
5. Examine the BGP EVPN MAC/IP routes (**RT-2**) received by PE1 for CE2's MAC address.
6. On PE3, list the MAC/IP routes received from peers for ELAN 10.

> **Note:** EVPN RT-2 routes expire after 300 seconds without traffic. Repeat the ping to refresh the advertisement if the routes disappear.

---

## Exercise 4.3 — Enable proxy-ARP for MAC-VRF

EVPN lets a MAC-VRF maintain a proxy-ARP table so the PE can answer local ARP requests itself, reducing BUM traffic sent into the core. Enable proxy-ARP for MAC-VRF 10 on **all** PEs.

### Configuration commands

```bash
enter candidate
/network-instance mac-vrf-10 protocols bgp-evpn bgp-instance 1 routes bridge-table mac-ip advertise true
/network-instance mac-vrf-10 bridge-table proxy-arp admin-state enable
/network-instance mac-vrf-10 bridge-table proxy-arp dynamic-learning admin-state enable
commit stay
```

### Verification commands

```bash
/show network-instance mac-vrf-10 bridge-table proxy-arp all
/show network-instance mac-vrf-10 bridge-table mac-table all
/show network-instance default protocols bgp routes evpn route-type 2 summary
/show network-instance default protocols bgp routes evpn route-type 2 mac-address <mac-address> detail
```

### Steps

1. On **all PE routers**, enable BGP-EVPN to include both MAC and IP addresses in the EVPN MAC/IP (RT-2) routes advertised for MAC-VRF 10's hosts.
2. On **all PE routers**, enable `dynamic-learning` for proxy-ARP so dynamically learned entries populate MAC-VRF 10's proxy-ARP table.
3. On **CE1 and CE2**, clear the ARP tables by bouncing the access port:

   ```bash
   /interface ethernet-1/2 admin-state disable
   commit stay
   /interface ethernet-1/2 admin-state enable
   commit stay
   ```

4. From CE1, ping CE2 at **192.168.1.2** — the ping should succeed.
5. On PE3, list the EVPN RT-2 routes received and verify an IP address is now present for both CE1 and CE2.
6. Verify MAC-VRF 10's MAC table on PE3 contains entries reaching CE1 and CE2 via EVPN tunnels to PE1 and PE2 respectively.
7. Display MAC-VRF 10's proxy-ARP table on PE3 — it should hold **192.168.1.1 → 00:00:00:99:02:01** and **192.168.1.2 → 00:00:00:99:02:02**, both learned from the received RT-2 routes.

---

## Troubleshooting

**No IMET routes from remote PEs**

- Verify MP-BGP EVPN sessions are established on all PE routers.
- Repeat the ping to refresh EVPN routes (RT-2 idle timeout ~300 s).

**MAC-VRF ping fails**

- Confirm SR-ISIS tunnels to remote PE loopbacks are active.
- Verify `allowed-tunnel-types [sr-isis]` on the MAC-VRF bgp-evpn instance.

---

## What's Next?

Continue to **[Lab 5 — Configuration of EVPN multi-homing in ELAN](lab5-evpn-multihoming.md)**.

**[Back to lab index](README.md)**
