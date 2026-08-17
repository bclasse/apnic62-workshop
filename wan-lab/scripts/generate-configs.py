#!/usr/bin/env python3
"""Generate SR Linux startup configs for the APNIC62 WAN lab topology."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIGS = ROOT / "configs"

NODES = {
    "r1-p1": {"num": 1, "role": "p", "net": "49.0001.0001.0001.0001.00"},
    "r2-p2": {"num": 2, "role": "p", "net": "49.0001.0002.0002.0002.00"},
    "r3-p3": {"num": 3, "role": "p", "net": "49.0001.0003.0003.0003.00"},
    "r4-p4": {"num": 4, "role": "p", "net": "49.0001.0004.0004.0004.00"},
    "r5-pe1": {"num": 5, "role": "pe", "net": "49.0001.0005.0005.0005.00"},
    "r6-pe2": {"num": 6, "role": "pe", "net": "49.0001.0006.0006.0006.00"},
    "r7-pe3": {"num": 7, "role": "pe", "net": "49.0001.0007.0007.0007.00"},
    "r8-pe4": {"num": 8, "role": "pe", "net": "49.0001.0008.0008.0008.00"},
    "r9-ce1": {"num": 9, "role": "ce", "net": None},
    "r10-ce2": {"num": 10, "role": "ce", "net": None},
    "r11-ce3": {"num": 11, "role": "ce", "net": None},
    "r12-ce4": {"num": 12, "role": "ce", "net": None},
}

# nodeA, portA, nodeB, portB
LINKS = [
    ("r1-p1", 1, "r5-pe1", 1), ("r1-p1", 2, "r2-p2", 2), ("r1-p1", 3, "r3-p3", 3),
    ("r1-p1", 4, "r4-p4", 4), ("r1-p1", 5, "r6-pe2", 5),
    ("r2-p2", 1, "r6-pe2", 1), ("r2-p2", 4, "r3-p3", 4), ("r2-p2", 3, "r4-p4", 3),
    ("r2-p2", 5, "r5-pe1", 5),
    ("r3-p3", 1, "r7-pe3", 1), ("r3-p3", 2, "r4-p4", 2), ("r3-p3", 5, "r8-pe4", 5),
    ("r4-p4", 5, "r7-pe3", 5), ("r4-p4", 1, "r8-pe4", 1),
    ("r5-pe1", 2, "r9-ce1", 1), ("r6-pe2", 2, "r10-ce2", 1), ("r7-pe3", 3, "r9-ce1", 2),
    ("r7-pe3", 4, "r11-ce3", 1),
    ("r8-pe4", 6, "r12-ce4", 1),
]


def port_for(local: str, remote: str) -> int:
    for a, pa, b, pb in LINKS:
        if a == local and b == remote:
            return pa
        if b == local and a == remote:
            return pb
    raise KeyError(f"no link {local} <-> {remote}")


def neighbors(node: str) -> list[str]:
    out = []
    for a, _, b, _ in LINKS:
        if a == node:
            out.append(b)
        elif b == node:
            out.append(a)
    return sorted(out, key=lambda n: NODES[n]["num"])


def link_ip(local: int, remote: int) -> str:
    lo, hi = sorted((local, remote))
    return f"10.{lo}.{hi}.{local}/27"


def hostname(node: str) -> str:
    parts = node.split("-")
    if len(parts) == 3:
        return f"{parts[0].upper()}-{parts[1].upper()}-{parts[2].upper()}"
    return f"{parts[0].upper()}-{parts[1].upper()}"


CE_IES_PE_PORT = {
    "r9-ce1": 1,
    "r10-ce2": 1,
    "r11-ce3": 1,
    "r12-ce4": 1,
}

PE_CE_SERVICE = {
    "r5-pe1": (2, 1),
    "r6-pe2": (2, 2),
    "r7-pe3": (4, 3),
    "r8-pe4": (6, 4),
}


def pe_uses_service_port(node: str, peer: str) -> bool:
    if node not in PE_CE_SERVICE:
        return False
    return port_for(node, peer) == PE_CE_SERVICE[node][0]


def pe_ip_vrf_symm_lines(node: str) -> list[str]:
    port, sn = PE_CE_SERVICE[node]
    ifname = f"ethernet-1/{port}"
    gw = f"172.16.{sn}.1"
    evpn = [
        "admin-state enable",
        "encapsulation-type mpls",
        "evi 100",
        "mpls next-hop-resolution allowed-tunnel-types [sr-isis]",
    ]
    lines = [
        f"set / interface {ifname} subinterface 0 type bridged",
        f"set / interface {ifname} subinterface 0 admin-state enable",
        "set / network-instance mac-vrf-symm type mac-vrf",
        "set / network-instance mac-vrf-symm admin-state enable",
        f"set / network-instance mac-vrf-symm interface {ifname}.0",
        "set / network-instance mac-vrf-symm interface irb0.1",
        "set / interface irb0 admin-state enable",
        "set / interface irb0 subinterface 1 admin-state enable",
        "set / interface irb0 subinterface 1 ipv4 admin-state enable",
        f"set / interface irb0 subinterface 1 ipv4 address {gw}/24",
        "set / network-instance ip-vrf-symm type ip-vrf",
        "set / network-instance ip-vrf-symm admin-state enable",
        "set / network-instance ip-vrf-symm interface irb0.1",
    ]
    lines.append("set / network-instance ip-vrf-symm protocols bgp-evpn bgp-instance 1 admin-state enable")
    for leaf in evpn[1:]:
        lines.append(f"set / network-instance ip-vrf-symm protocols bgp-evpn bgp-instance 1 {leaf}")
    return lines


def ce_ies_subnet(node: str) -> int:
    return NODES[node]["num"] - 8


def ce_uses_ies_port(node: str, peer: str) -> bool:
    if node not in CE_IES_PE_PORT:
        return False
    return port_for(node, peer) == CE_IES_PE_PORT[node]


def ce_ies_preconfig_lines(node: str) -> list[str]:
    port = CE_IES_PE_PORT[node]
    sn = ce_ies_subnet(node)
    ifname = f"ethernet-1/{port}"
    host = f"172.16.{sn}.10"
    gateway = f"172.16.{sn}.1"
    return [
        "set / network-instance ies-1 type ip-vrf",
        "set / network-instance ies-1 admin-state enable",
        f"set / interface {ifname} subinterface 0 admin-state enable",
        f"set / interface {ifname} subinterface 0 ipv4 admin-state enable",
        f"set / interface {ifname} subinterface 0 ipv4 address {host}/24",
        f"set / network-instance ies-1 interface {ifname}.0",
        "set / network-instance ies-1 next-hop-groups group gw admin-state enable",
        "set / network-instance ies-1 next-hop-groups group gw nexthop 1 admin-state enable",
        f"set / network-instance ies-1 next-hop-groups group gw nexthop 1 ip-address {gateway}",
        "set / network-instance ies-1 static-routes route 0.0.0.0/0 admin-state enable",
        "set / network-instance ies-1 static-routes route 0.0.0.0/0 next-hop-group gw",
    ]


def uses_vlan_access(node: str, peer: str, lab: str) -> bool:
    if node == "r5-pe1" and peer == "r9-ce1" and lab in ("lab1-start", "lab4-start", "lab5-start"):
        return True
    if node == "r9-ce1" and peer == "r5-pe1" and lab == "lab1-start":
        return True
    return False


def mpls_sr_label_range_lines() -> list[str]:
    return [
        "set / system mpls label-ranges static srgb-range-1 shared true start-label 16001 end-label 16999",
        "set / system mpls label-ranges dynamic srlb-dynamic-isis start-label 15001 end-label 15999",
    ]


def include_sr_preconfig(node: str, lab: str) -> bool:
    if NODES[node]["role"] not in ("p", "pe"):
        return False
    if lab == "lab1-start" and node in ("r1-p1", "r5-pe1"):
        return False
    return True


def isis_sr_preconfig_lines(router_num: int) -> list[str]:
    return [
        "set / network-instance default protocols isis dynamic-label-block srlb-dynamic-isis",
        "set / network-instance default protocols isis instance il segment-routing mpls dynamic-adjacency-sids all-interfaces true",
        f"set / network-instance default protocols isis instance il interface system0.0 segment-routing mpls ipv4-node-sid index {router_num}",
        "set / network-instance default segment-routing mpls global-block label-range srgb-range-1",
    ]


def pe_ce_vlan_access_lines() -> list[str]:
    return [
        "set / interface ethernet-1/2 vlan-tagging true",
        "set / interface ethernet-1/2 ethernet mac-address 00:00:00:00:02:01",
        "set / interface ethernet-1/2 subinterface 10 type bridged",
        "set / interface ethernet-1/2 subinterface 10 admin-state enable",
        "set / interface ethernet-1/2 subinterface 10 vlan encap single-tagged vlan-id 10",
    ]


def build_config(node: str, lab: str) -> str:
    info = NODES[node]
    n = info["num"]
    lo = f"10.10.10.{n}"
    lines = [
        f"set / system name host-name {hostname(node)}",
        "set / interface system0 admin-state enable",
        "set / interface system0 subinterface 0 ipv4 admin-state enable",
        f"set / interface system0 subinterface 0 ipv4 address {lo}/32",
        "set / network-instance default admin-state enable",
        "set / network-instance default interface system0.0",
    ]
    for peer in neighbors(node):
        port = port_for(node, peer)
        ifname = f"ethernet-1/{port}"
        lines.append(f"set / interface {ifname} admin-state enable")
        if uses_vlan_access(node, peer, lab):
            continue
        if pe_uses_service_port(node, peer):
            continue
        if ce_uses_ies_port(node, peer):
            continue
        ip = link_ip(n, NODES[peer]["num"])
        lines.extend([
            f"set / interface {ifname} subinterface 0 admin-state enable",
            f"set / interface {ifname} subinterface 0 ipv4 admin-state enable",
            f"set / interface {ifname} subinterface 0 ipv4 address {ip}",
            f"set / network-instance default interface {ifname}.0",
        ])
    if node in CE_IES_PE_PORT:
        lines.extend(ce_ies_preconfig_lines(node))
    if info["role"] in ("p", "pe"):
        sr = include_sr_preconfig(node, lab)
        if sr:
            lines.append("set / network-instance default protocols isis dynamic-label-block srlb-dynamic-isis")
        lines.extend([
            "set / network-instance default protocols isis instance il admin-state enable",
            f"set / network-instance default protocols isis instance il net [ {info['net']} ]",
        ])
        if sr:
            lines.append(
                "set / network-instance default protocols isis instance il segment-routing mpls dynamic-adjacency-sids all-interfaces true"
            )
        lines.extend([
            "set / network-instance default protocols isis instance il interface system0.0",
            "set / network-instance default protocols isis instance il interface system0.0 passive true",
        ])
        if sr:
            lines.append(
                f"set / network-instance default protocols isis instance il interface system0.0 segment-routing mpls ipv4-node-sid index {n}"
            )
        for peer in neighbors(node):
            if uses_vlan_access(node, peer, lab):
                continue
            if pe_uses_service_port(node, peer):
                continue
            port = port_for(node, peer)
            ifname = f"ethernet-1/{port}"
            lines.extend([
                f"set / network-instance default protocols isis instance il interface {ifname}.0",
                f"set / network-instance default protocols isis instance il interface {ifname}.0 circuit-type point-to-point",
                f"set / network-instance default protocols isis instance il interface {ifname}.0 level 2",
                f"set / network-instance default protocols isis instance il interface {ifname}.0 level 2 metric 10",
            ])
        if sr:
            lines.append("set / network-instance default segment-routing mpls global-block label-range srgb-range-1")
            lines.extend(mpls_sr_label_range_lines())
    if node in PE_CE_SERVICE:
        lines.extend(pe_ip_vrf_symm_lines(node))
    if lab in ("lab4-start", "lab5-start") and node == "r5-pe1":
        lines.extend(pe_ce_vlan_access_lines())
    return "\n".join(lines) + "\n"


def main() -> None:
    # #region agent log
    import json, time
    _log_path = Path(__file__).resolve().parents[2] / "debug-984e35.log"
    def _dbg(hypothesis_id: str, message: str, data: dict) -> None:
        payload = {"sessionId": "984e35", "runId": "gen-configs", "hypothesisId": hypothesis_id,
                   "location": "generate-configs.py:main", "message": message, "data": data,
                   "timestamp": int(time.time() * 1000)}
        with _log_path.open("a", encoding="utf-8") as f:
            f.write(json.dumps(payload) + "\n")
    for node in ("r5-pe1", "r6-pe2", "r2-p2", "r7-pe3", "r8-pe4"):
        mapping = {f"ethernet-1/{port_for(node, peer)}": peer for peer in neighbors(node)}
        _dbg("H1", f"port map for {node}", {"node": node, "mapping": mapping})
    # #endregion
    for lab in ("lab1-start", "lab2-start", "lab3-start", "lab4-start", "lab5-start"):
        out = CONFIGS / lab
        out.mkdir(parents=True, exist_ok=True)
        for node in NODES:
            (out / f"{node}.cfg").write_text(build_config(node, lab), encoding="utf-8")
        print(f"wrote {len(NODES)} configs to {out}")


if __name__ == "__main__":
    main()
