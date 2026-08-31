# Containerlab Workshop: Activity 0 - Environment deployment

1. **Containerlab and Docker installation**
Execute the following command:

    ```bash
    curl -sL https://containerlab.dev/setup | sudo -E bash -s "all"
    ```

2. **Pull docker images**
Retrieve the necessary Docker images for the rest of the workshop:

    ```bash
    docker pull nokiacontainerlabregistry.nznog.org/ghcr/srl-labs/network-multitool:v0.5.0
    docker pull nokiacontainerlabregistry.nznog.org/ghcr/nokia/srlinux:24.10.1
    docker pull nokiacontainerlabregistry.nznog.org/ghcr/nokia/srlinux:25.10.1
    docker pull nokiacontainerlabregistry.nznog.org/ghcr/openconfig/gnmic:0.39.1
    docker pull nokiacontainerlabregistry.nznog.org/quay/prometheus/prometheus:v2.54.1
    docker pull nokiacontainerlabregistry.nznog.org/docker/grafana/grafana:11.2.0
    docker pull nokiacontainerlabregistry.nznog.org/docker/grafana/promtail:3.2.0
    docker pull nokiacontainerlabregistry.nznog.org/docker/grafana/loki:3.2.0
    docker pull nokiacontainerlabregistry.nznog.org/ghcr/srl-labs/nornir-srl:latest
    docker pull nokiacontainerlabregistry.nznog.org/ghcr/kaelemc/wireshark-vnc-docker:latest
    docker pull nokiacontainerlabregistry.nznog.org/ghcr/siemens/packetflix:latest
    docker pull nokiacontainerlabregistry.nznog.org/ghcr/siemens/ghostwire:latest
    ```
