# 🧰 Containerlab Workshop

Hands-on introduction to [Containerlab](https://containerlab.dev/) — deploying and managing topologies, startup configuration and licensing, generic node configuration, traffic capture, and telemetry.

Work through the activities in order; each one is self-contained in its own directory.

| Activity | Topic |
|----------|-------|
| [0 — Environment deployment](00-install/README.md) | Install Containerlab and Docker, pull the images |
| [1 — Basic topology management](01-syntax/README.md) | Deploy single-node topologies, inspect them, add nodes and links, tidy the definition |
| [2 — VS Code extension discovery](02-vscode/README.md) | Deploy and manage topologies from VS Code, contextual menus, the visual editor |
| [3 — Startup configuration and licensing](03-startup/README.md) | SR Linux licensing for hardware types such as IXR X1b, and startup configs |
| [4 — Generic node configuration](04-env/README.md) | File binds, port mapping and environment variables, using Grafana as the example |
| [5 — Traffic capture and link impairments](05-traffic/README.md) | Generate traffic, capture live with EdgeShark, then simulate impairments |
| [6 — SR Linux telemetry lab](06-telemetry/README.md) | A data-centre fabric with gNMIc, Prometheus, Loki and Grafana |

`solutions/` holds the finished topology files for the activities that ask you to build one.

## Relationship to the rest of this repository

This workshop stands on its own and teaches Containerlab itself. The [WAN lab](../wan-lab/README.md) then applies it: Labs 1–5 there use Containerlab to run a 12-router Nokia SR Linux topology for segment routing, SR-MPLS traffic engineering and EVPN.

Activity 3's licensing material is directly relevant — the WAN lab's `ixr-x1b` nodes need the licence described in [`srl-license/`](../srl-license/README.md).

## Credit

Sourced from [bclasse/containerlab-workshop](https://github.com/bclasse/containerlab-workshop). Activity 6 is based on [srl-labs/srl-telemetry-lab](https://github.com/srl-labs/srl-telemetry-lab) and keeps its own [LICENSE](06-telemetry/LICENSE).
