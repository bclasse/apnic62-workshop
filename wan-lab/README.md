# 🌐 APNIC62 WAN Lab

> **Hands-on Nokia SR Linux Segment Routing & EVPN Workshop**

Welcome to the APNIC62 WAN Lab! This workshop provides **five comprehensive guides** covering IS-IS Segment Routing, SR-MPLS traffic engineering, and EVPN-MPLS services on a unified 12-router WAN topology.

> **Note:** This workshop uses **SR-ISIS** as the sole MPLS transport. LDP is not used.

---

## 📚 Workshop Structure

### 🔧 [Lab 1: IS-IS SR + MP-BGP for EVPN](lab1-isis-sr-evpn-bgp.md)

Configure IS-IS segment routing, MP-BGP EVPN sessions, CE access, and IP-VRF transport over SR-ISIS tunnels.

**What you'll learn:**
- MPLS label blocks (SRGB, SRLB) for segment routing
- IS-IS SR node-SIDs and adjacency-SIDs
- MP-BGP EVPN PE-to-PE sessions
- IP-VRF transport using SR-ISIS

**Duration:** ~120 minutes

---

### 📡 [Lab 2: TE Link Attributes](lab2-te-link-attributes.md)

Configure and advertise traffic engineering link attributes via IS-IS.

**What you'll learn:**
- Admin groups and SRLGs
- TE interface membership
- IS-IS TE database and advertisement

**Duration:** ~45 minutes

---

### 🛤️ [Lab 3: Uncolored SR-MPLS TE Policies](lab3-sr-te-policies.md)

Build SR-MPLS TE policies with path constraints, BFD, and redundancy.

**What you'll learn:**
- Uncolored SR-MPLS TE policies (IGP and TE metrics)
- Explicit paths, excluded hops, and BSID label blocks
- Secondary paths with SRLG diversity
- IP-VRF over TE policy transport

**Duration:** ~180 minutes

---

### 🔀 [Lab 4: EVPN ELAN](lab4-evpn-elan.md)

Deploy a Layer 2 EVPN ELAN service using SR-ISIS transport.

**What you'll learn:**
- EVPN service and ES label ranges
- MAC-VRF with SR-ISIS transport (no LDP)
- EVPN route verification (RT-2, RT-3)
- Proxy-ARP for MAC-VRF

**Duration:** ~90 minutes

---

### 🔗 [Lab 5: EVPN Multi-homing ELAN](lab5-evpn-multihoming.md)

Configure all-active and single-active EVPN multi-homing.

**What you'll learn:**
- LAG and Ethernet Segments on R5-PE1 + R7-PE3
- EVPN A-D and ES routes
- DF election (default and preference-based)
- ECMP aliasing and ES failure scenarios

**Duration:** ~150 minutes

---

## ✅ Prerequisites

Before starting, ensure you have:

- Linux host (or WSL2) with **Docker** and **[containerlab](https://containerlab.dev/)**
- **Nokia SR Linux license file** at `srl-license/srlinux.license` (provided by workshop organizers)
- SR Linux image: `ghcr.io/nokia/srlinux:25.3`
- **~24–36 GB RAM** and **12+ vCPUs** for 12× IXR-X1B nodes
- Basic understanding of IS-IS, BGP, MPLS, and EVPN concepts

---

## 🚀 Getting Started

1. Clone this repository and place your license file:

```bash
git clone https://github.com/thcorre/apnic62-workshop.git
cd apnic62-workshop
# copy srlinux.license to srl-license/srlinux.license
```

2. Deploy Lab 1:

```bash
cd wan-lab
chmod +x scripts/*.sh
./scripts/deploy-lab.sh 1
```

3. Connect to student routers:

```bash
ssh admin@r1-p1    # password: NokiaSrl1!
ssh admin@r5-pe1
ssh admin@r9-ce1
```

4. Follow [Lab 1](lab1-isis-sr-evpn-bgp.md) and continue in order through Lab 5.

> **💡 Tip:** Each lab has its own topology file (`apnic62-wan-lab<N>.clab.yml`) and config directory (`configs/lab<N>-start/`). Run `./scripts/deploy-lab.sh <N>` before starting that lab.

---

## 📖 Lab Topology

```
     R1-P1 ─── R5-PE1 ─── R9-CE1
       │    ╲    │    ╱
     R2-P2 ─── R6-PE2 ─── R10-CE2
       │    ╲    │    ╱
     R3-P3 ─── R7-PE3 ─── (MH to R9)
       │         │
     R4-P4 ─── R8-PE4
```

- **Underlay:** IS-IS L2, SR-ISIS MPLS transport
- **Overlay:** MP-BGP EVPN (AS 65530) among PE routers
- **Details:** [Topology and addressing](../docs/topology.md) | [Router naming](../docs/router-naming.md)

---

## 🔄 Reset / Redeploy

```bash
cd wan-lab
./scripts/deploy-lab.sh <lab-number>
# or manually:
clab destroy -t apnic62-wan-lab<N>.clab.yml --cleanup
clab deploy -t apnic62-wan-lab<N>.clab.yml --reconfigure
```

---

## 🛠️ Additional Resources

- [SR Linux Documentation](https://documentation.nokia.com/srlinux/)
- [Learn SR Linux](https://learn.srlinux.dev/)
- [Containerlab SR Linux kind](https://containerlab.dev/manual/kinds/srl/)

---

## 🤝 Getting Help

1. Check the **Troubleshooting** section in each lab guide
2. Verify your license file and containerlab deployment (`clab inspect`)
3. Run `./scripts/verify-lab.sh <N>` for a quick smoke check
4. Ask your lab instructor

---

**Ready to begin?** 🎯 Head to [Lab 1: IS-IS SR + MP-BGP for EVPN](lab1-isis-sr-evpn-bgp.md)
