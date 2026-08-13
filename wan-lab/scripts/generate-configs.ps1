# Generate SR Linux startup configs for APNIC62 WAN lab
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Configs = Join-Path $Root "configs"

$Nodes = @{
    "r1-p1"  = @{ num = 1; role = "p";  net = "49.0001.0001.0001.0001.00" }
    "r2-p2"  = @{ num = 2; role = "p";  net = "49.0001.0002.0002.0002.00" }
    "r3-p3"  = @{ num = 3; role = "p";  net = "49.0001.0003.0003.0003.00" }
    "r4-p4"  = @{ num = 4; role = "p";  net = "49.0001.0004.0004.0004.00" }
    "r5-pe1" = @{ num = 5; role = "pe"; net = "49.0001.0005.0005.0005.00" }
    "r6-pe2" = @{ num = 6; role = "pe"; net = "49.0001.0006.0006.0006.00" }
    "r7-pe3" = @{ num = 7; role = "pe"; net = "49.0001.0007.0007.0007.00" }
    "r8-pe4" = @{ num = 8; role = "pe"; net = "49.0001.0008.0008.0008.00" }
    "r9-ce1" = @{ num = 9; role = "ce"; net = $null }
    "r10-ce2"= @{ num = 10; role = "ce"; net = $null }
    "r11-ce3"= @{ num = 11; role = "ce"; net = $null }
    "r12-ce4"= @{ num = 12; role = "ce"; net = $null }
}

# Bidirectional links: nodeA, portA, nodeB, portB
$Links = @(
    @("r1-p1",1,"r2-p2",1), @("r1-p1",2,"r3-p3",1), @("r1-p1",3,"r4-p4",1),
    @("r1-p1",4,"r5-pe1",1), @("r1-p1",5,"r6-pe2",1),
    @("r2-p2",2,"r3-p3",2), @("r2-p2",3,"r4-p4",2), @("r2-p2",4,"r5-pe1",2),
    @("r2-p2",5,"r6-pe2",2), @("r2-p2",6,"r8-pe4",1),
    @("r3-p3",3,"r4-p4",3), @("r3-p3",4,"r5-pe1",3), @("r3-p3",5,"r6-pe2",3),
    @("r3-p3",6,"r7-pe3",1),
    @("r4-p4",4,"r5-pe1",4), @("r4-p4",5,"r6-pe2",4), @("r4-p4",6,"r7-pe3",2),
    @("r4-p4",7,"r8-pe4",2),
    @("r5-pe1",5,"r9-ce1",1), @("r6-pe2",5,"r10-ce2",1), @("r7-pe3",3,"r9-ce1",2),
    @("r8-pe4",5,"r11-ce3",1), @("r8-pe4",6,"r12-ce4",1)
)

function Get-LinkIp($local, $remote) {
    $lo = [Math]::Min($local, $remote)
    $hi = [Math]::Max($local, $remote)
    return "10.$lo.$hi.$local/27"
}

function Get-PortFor($local, $remote) {
    foreach ($l in $Links) {
        if ($l[0] -eq $local -and $l[2] -eq $remote) { return $l[1] }
        if ($l[2] -eq $local -and $l[0] -eq $remote) { return $l[3] }
    }
    throw "no link $local $remote"
}

function Get-Neighbors($node) {
    $n = @()
    foreach ($l in $Links) {
        if ($l[0] -eq $node) { $n += $l[2] }
        elseif ($l[2] -eq $node) { $n += $l[0] }
    }
    return $n | Sort-Object { $Nodes[$_].num }
}

function Get-Hostname($node) {
    $p = $node -split '-'
    if ($p.Length -eq 3) { return "$($p[0].ToUpper())-$($p[1].ToUpper())-$($p[2].ToUpper())" }
    return "$($p[0].ToUpper())-$($p[1].ToUpper())"
}

function Build-Config($node, $lab) {
    $info = $Nodes[$node]
    $n = $info.num
    $lo = "10.10.10.$n"
    $lines = @(
        "set / system name host-name value $(Get-Hostname $node)",
        "set / interface system0 admin-state enable",
        "set / interface system0 subinterface 0 ipv4 admin-state enable",
        "set / interface system0 subinterface 0 ipv4 address $lo/32",
        "set / network-instance default admin-state enable",
        "set / network-instance default interface system0.0"
    )
    foreach ($peer in (Get-Neighbors $node)) {
        $port = Get-PortFor $node $peer
        $if = "ethernet-1/$port"
        $ip = Get-LinkIp $n $Nodes[$peer].num
        $lines += @(
            "set / interface $if admin-state enable",
            "set / interface $if subinterface 0 admin-state enable",
            "set / interface $if subinterface 0 ipv4 admin-state enable",
            "set / interface $if subinterface 0 ipv4 address $ip",
            "set / network-instance default interface $if.0"
        )
    }
    if ($info.role -in @("p","pe")) {
        $lines += @(
            "set / network-instance default protocols isis admin-state enable",
            "set / network-instance default protocols isis instance il admin-state enable",
            "set / network-instance default protocols isis instance il net [ $($info.net) ]",
            "set / network-instance default protocols isis instance il interface system0.0",
            "set / network-instance default protocols isis instance il interface system0.0 passive true"
        )
        foreach ($peer in (Get-Neighbors $node)) {
            $port = Get-PortFor $node $peer
            $if = "ethernet-1/$port"
            $lines += @(
                "set / network-instance default protocols isis instance il interface $if.0",
                "set / network-instance default protocols isis instance il interface $if.0 circuit-type point-to-point",
                "set / network-instance default protocols isis instance il interface $if.0 level 2 metric 10"
            )
        }
    }
    if ($lab -eq "lab1-start" -and $node -eq "r5-pe1") {
        $lines += @(
            "set / network-instance ip-vrf-symm type ip-vrf",
            "set / network-instance ip-vrf-symm admin-state enable",
            "set / interface irb0 admin-state enable",
            "set / interface irb0 subinterface 1 type routed",
            "set / interface irb0 subinterface 1 admin-state enable",
            "set / interface irb0 subinterface 1 ipv4 admin-state enable",
            "set / interface irb0 subinterface 1 ipv4 address 172.16.1.1/24",
            "set / network-instance ip-vrf-symm interface irb0.1",
            "set / network-instance ip-vrf-symm protocols bgp-evpn bgp-instance 1 admin-state enable",
            "set / network-instance ip-vrf-symm protocols bgp-evpn bgp-instance 1 encapsulation-type mpls",
            "set / network-instance ip-vrf-symm protocols bgp-evpn bgp-instance 1 evi 100"
        )
    }
    if ($lab -in @("lab4-start","lab5-start") -and $node -eq "r5-pe1") {
        $lines += @(
            "set / interface ethernet-1/5 admin-state enable",
            "set / interface ethernet-1/5 vlan-tagging true",
            "set / interface ethernet-1/5 ethernet mac-address 00:00:00:00:02:01",
            "set / interface ethernet-1/5 subinterface 10 type bridged",
            "set / interface ethernet-1/5 subinterface 10 admin-state enable",
            "set / interface ethernet-1/5 subinterface 10 vlan encap single-tagged vlan-id 10"
        )
    }
    return ($lines -join "`n") + "`n"
}

foreach ($lab in @("lab1-start","lab2-start","lab3-start","lab4-start","lab5-start")) {
    $out = Join-Path $Configs $lab
    New-Item -ItemType Directory -Force -Path $out | Out-Null
    foreach ($node in $Nodes.Keys) {
        Build-Config $node $lab | Set-Content -Path (Join-Path $out "$node.cfg") -Encoding UTF8
    }
    Write-Host "wrote $($Nodes.Count) configs to $out"
}
