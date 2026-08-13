# Generate SR Linux startup configs for APNIC62 WAN lab
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Configs = Join-Path $Root "configs"
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

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

$Links = @(
    @("r1-p1",1,"r2-p2",1), @("r1-p1",2,"r3-p3",1), @("r1-p1",3,"r4-p4",1),
    @("r1-p1",4,"r5-pe1",1), @("r1-p1",5,"r6-pe2",1),
    @("r2-p2",2,"r3-p3",2), @("r2-p2",3,"r4-p4",2), @("r2-p2",4,"r5-pe1",2),
    @("r2-p2",5,"r6-pe2",2),
    @("r3-p3",3,"r4-p4",3), @("r3-p3",4,"r8-pe4",1),
    @("r3-p3",6,"r7-pe3",1),
    @("r4-p4",6,"r7-pe3",2),
    @("r4-p4",7,"r8-pe4",2),
    @("r5-pe1",5,"r9-ce1",1), @("r6-pe2",5,"r10-ce2",1), @("r7-pe3",3,"r9-ce1",2),
    @("r7-pe3",4,"r11-ce3",1),
    @("r8-pe4",6,"r12-ce4",1)
)

function Add-SetPath([System.Collections.Generic.List[string]]$lines, [string]$path) {
    $lines.Add("set / $path") | Out-Null
}

function Add-SetLeaf([System.Collections.Generic.List[string]]$lines, [string]$path, [string]$leaf, [string]$value) {
    if ($null -ne $value -and $value -ne "") {
        $lines.Add("set / $path $leaf $value") | Out-Null
    } else {
        $lines.Add("set / $path $leaf") | Out-Null
    }
}

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

function Test-UsesVlanAccess($node, $peer, $lab) {
    if ($node -eq "r5-pe1" -and $peer -eq "r9-ce1" -and $lab -in @("lab1-start","lab4-start","lab5-start")) { return $true }
    if ($node -eq "r9-ce1" -and $peer -eq "r5-pe1" -and $lab -eq "lab1-start") { return $true }
    return $false
}

function Add-PeCeVlanAccess($lines) {
    Add-SetLeaf $lines "interface ethernet-1/5" "vlan-tagging" "true"
    Add-SetPath $lines "interface ethernet-1/5 ethernet"
    Add-SetLeaf $lines "interface ethernet-1/5 ethernet" "mac-address" "00:00:00:00:02:01"
    Add-SetPath $lines "interface ethernet-1/5 subinterface 10"
    Add-SetLeaf $lines "interface ethernet-1/5 subinterface 10" "type" "bridged"
    Add-SetLeaf $lines "interface ethernet-1/5 subinterface 10" "admin-state" "enable"
    Add-SetPath $lines "interface ethernet-1/5 subinterface 10 vlan encap single-tagged"
    Add-SetLeaf $lines "interface ethernet-1/5 subinterface 10 vlan encap single-tagged" "vlan-id" "10"
}

function Build-Config($node, $lab) {
    $info = $Nodes[$node]
    $n = $info.num
    $lo = "10.10.10.$n"
    $lines = [System.Collections.Generic.List[string]]::new()

    Add-SetPath $lines "system"
    $lines.Add("set / system name host-name $(Get-Hostname $node)") | Out-Null

    Add-SetPath $lines "interface system0"
    Add-SetLeaf $lines "interface system0" "admin-state" "enable"
    Add-SetPath $lines "interface system0 subinterface 0"
    Add-SetLeaf $lines "interface system0 subinterface 0" "admin-state" "enable"
    Add-SetPath $lines "interface system0 subinterface 0 ipv4"
    Add-SetLeaf $lines "interface system0 subinterface 0 ipv4" "admin-state" "enable"
    Add-SetLeaf $lines "interface system0 subinterface 0 ipv4" "address" "$lo/32"

    Add-SetPath $lines "network-instance default"
    Add-SetLeaf $lines "network-instance default" "admin-state" "enable"
    Add-SetLeaf $lines "network-instance default" "interface" "system0.0"

    foreach ($peer in (Get-Neighbors $node)) {
        $port = Get-PortFor $node $peer
        $if = "ethernet-1/$port"
        Add-SetPath $lines "interface $if"
        Add-SetLeaf $lines "interface $if" "admin-state" "enable"
        if (Test-UsesVlanAccess $node $peer $lab) { continue }
        $ip = Get-LinkIp $n $Nodes[$peer].num
        Add-SetPath $lines "interface $if subinterface 0"
        Add-SetLeaf $lines "interface $if subinterface 0" "admin-state" "enable"
        Add-SetPath $lines "interface $if subinterface 0 ipv4"
        Add-SetLeaf $lines "interface $if subinterface 0 ipv4" "admin-state" "enable"
        Add-SetLeaf $lines "interface $if subinterface 0 ipv4" "address" $ip
        Add-SetLeaf $lines "network-instance default" "interface" "$if.0"
    }

    if ($info.role -in @("p","pe")) {
        Add-SetPath $lines "network-instance default protocols isis"
        Add-SetPath $lines "network-instance default protocols isis instance il"
        Add-SetLeaf $lines "network-instance default protocols isis instance il" "admin-state" "enable"
        Add-SetLeaf $lines "network-instance default protocols isis instance il" "net" "[ $($info.net) ]"
        Add-SetPath $lines "network-instance default protocols isis instance il interface system0.0"
        Add-SetLeaf $lines "network-instance default protocols isis instance il interface system0.0" "passive" "true"
        foreach ($peer in (Get-Neighbors $node)) {
            if (Test-UsesVlanAccess $node $peer $lab) { continue }
            $port = Get-PortFor $node $peer
            $if = "ethernet-1/$port"
            Add-SetPath $lines "network-instance default protocols isis instance il interface $if.0"
            Add-SetLeaf $lines "network-instance default protocols isis instance il interface $if.0" "circuit-type" "point-to-point"
            Add-SetPath $lines "network-instance default protocols isis instance il interface $if.0 level 2"
            Add-SetLeaf $lines "network-instance default protocols isis instance il interface $if.0 level 2" "metric" "10"
        }
    }

    if ($lab -eq "lab1-start" -and $node -eq "r5-pe1") {
        Add-PeCeVlanAccess $lines
        Add-SetPath $lines "network-instance ip-vrf-symm"
        Add-SetLeaf $lines "network-instance ip-vrf-symm" "type" "ip-vrf"
        Add-SetLeaf $lines "network-instance ip-vrf-symm" "admin-state" "enable"
        Add-SetPath $lines "interface irb0"
        Add-SetLeaf $lines "interface irb0" "admin-state" "enable"
        Add-SetPath $lines "interface irb0 subinterface 1"
        Add-SetLeaf $lines "interface irb0 subinterface 1" "admin-state" "enable"
        Add-SetPath $lines "interface irb0 subinterface 1 ipv4"
        Add-SetLeaf $lines "interface irb0 subinterface 1 ipv4" "admin-state" "enable"
        Add-SetLeaf $lines "interface irb0 subinterface 1 ipv4" "address" "172.16.1.1/24"
        Add-SetLeaf $lines "network-instance ip-vrf-symm" "interface" "irb0.1"
        Add-SetPath $lines "network-instance ip-vrf-symm protocols bgp-evpn bgp-instance 1"
        Add-SetLeaf $lines "network-instance ip-vrf-symm protocols bgp-evpn bgp-instance 1" "admin-state" "enable"
        Add-SetLeaf $lines "network-instance ip-vrf-symm protocols bgp-evpn bgp-instance 1" "encapsulation-type" "mpls"
        Add-SetLeaf $lines "network-instance ip-vrf-symm protocols bgp-evpn bgp-instance 1" "evi" "100"
        Add-SetPath $lines "network-instance ip-vrf-symm protocols bgp-evpn bgp-instance 1 mpls next-hop-resolution"
        Add-SetLeaf $lines "network-instance ip-vrf-symm protocols bgp-evpn bgp-instance 1 mpls next-hop-resolution" "allowed-tunnel-types" "[sr-isis]"
    }

    if ($lab -in @("lab4-start","lab5-start") -and $node -eq "r5-pe1") {
        Add-PeCeVlanAccess $lines
    }

    return (($lines -join "`n") + "`n")
}

foreach ($lab in @("lab1-start","lab2-start","lab3-start","lab4-start","lab5-start")) {
    $out = Join-Path $Configs $lab
    New-Item -ItemType Directory -Force -Path $out | Out-Null
    foreach ($node in $Nodes.Keys) {
        $path = Join-Path $out "$node.cfg"
        [System.IO.File]::WriteAllText($path, (Build-Config $node $lab), $Utf8NoBom)
    }
    Write-Host "wrote $($Nodes.Count) configs to $out"
}
