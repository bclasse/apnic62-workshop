# Containerlab Workshop: Activity 4 - Generic node configuration

This activity explores key configuration capabilities for all kinds of nodes within Containerlab, using a Grafana instance as a practical example. You will learn about file binding, port mapping, and environment variable management.

---

## Task 4: Deploying a Grafana instance

This task demonstrates how to deploy a Grafana instance, focusing on common deployment requirements like persistent storage (via binds), network accessibility (via port mapping), and application-specific settings (via environment variables).

1. **Deploy the topology and examine file binds and permissions:**
    * Deploy the topology using your favourite method.
    * **Understanding binds:** Containerlab allows you to "bind" local host directories or files into the container's filesystem. This is crucial for persistent storage (e.g., Grafana data, configurations) or injecting custom files.
    * **Locate binds in Topology:** Open the `04-env.clab.yml` file. Look for the `binds:` section under the Grafana node definition.

        ```yaml
        nodes:
          grafana:
            kind: linux
            image: grafana/grafana:11.2.0
            # ...
            binds:
            - configs/grafana/datasource.yml:/etc/grafana/provisioning/datasources/datasource.yaml:ro
        ```

    * Observe how local paths (e.g., `configs/grafana/datasource.yml`) are mapped to container paths (e.g., `/etc/grafana/provisioning/datasources/datasource.yaml`).
    * Note the `ro` (read-only) that causes the volume to be mounted into the container as read-only.

    * **Verify binds in container:**
        * Connect to the Grafana container using docker exec:

            ```bash
            docker exec -it clab-04-env-grafana bash 
            ```

        * Navigate to the bound paths (e.g., `/etc/grafana/provisioning/datasources/`) and verify that the files/directories from your host are present.
        * Test permissions by trying to modify a file in a read-only bound directory (it should fail).

2. **Examine port binding:**
    * To access services running inside a container from your host machine, you need to map the container's port to a port on the host.
    * In `04-grafana-node.clab.yml`, find the `ports:` section under the Grafana node definition.

        ```yaml
        nodes:
          grafana:
            kind: linux
            image: grafana/grafana:11.2.0
            # ...
            ports:
            - 3000:3000
        ```

        * This configuration makes Grafana, which typically listens on port 3000 inside the container, accessible on port 3000 of your host machine.
        Note that during this workshop, firewall rules on the network where your VM is hosted might be active and prevent reaching port 3000.
        To work around this, use port forwarding directly on VSCode.

    * **Access Grafana:**
        * Open your web browser and navigate to `http://localhost:3000`, you should see the Grafana login page.

3. **Examine environment variables:**
    * Environment variables are a common way to pass configuration settings to applications running inside containers without modifying the container image itself.
    * In `04-env.clab.yml`, look for the `env:` section under the Grafana node definition.

        ```yaml
        nodes:
          grafana:
            kind: linux
            image: grafana/grafana:11.2.0
            # ...
            env:
                GF_INSTALL_PLUGINS: andrewbmchugh-flow-panel
        ```

    * Connect to the Grafana container and execute the `env` command.
    * You will see a list of all environment variables, including those defined in your topology file .
