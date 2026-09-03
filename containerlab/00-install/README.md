# Containerlab Workshop: Activity 0 - Environment deployment

1. **Containerlab and Docker installation**
Execute the following command:

    ```bash
    curl -sL https://containerlab.dev/setup | sudo -E bash -s "all"
    ```

2. **Pull docker images**
Retrieve the necessary Docker images for the rest of the workshop:

    ```bash
    docker pull ghcr.io/srl-labs/network-multitool:v0.5.0
    docker pull ghcr.io/nokia/srlinux:24.10.1
    docker pull ghcr.io/nokia/srlinux:25.10.1
    docker pull ghcr.io/openconfig/gnmic:0.39.1
    docker pull quay.io/prometheus/prometheus:v2.54.1
    docker pull grafana/grafana:11.2.0
    docker pull grafana/promtail:3.2.0
    docker pull grafana/loki:3.2.0
    docker pull ghcr.io/srl-labs/nornir-srl:latest
    docker pull ghcr.io/kaelemc/wireshark-vnc-docker:latest
    docker pull ghcr.io/siemens/packetflix:latest
    docker pull ghcr.io/siemens/ghostwire:latest
    ```
