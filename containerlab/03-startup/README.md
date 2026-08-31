# Containerlab Workshop: Activity 3 - Startup configuration and licensing

This activity focuses on advanced Containerlab features for managing network device startup configurations and licensing, specifically for SR Linux.

---

## Task 3a: License management for SR Linux

This task demonstrates how to apply licenses to SR Linux nodes that require specific hardware types, such as IXR X1b, which necessitate a license to start correctly in a containerised environment.

1. **Modify node type:**
    * Edit the `03-startup.clab.yml` file.
    * Locate the SR Linux kind definition and change its `type` attribute to `ixr-x1b`.

        ```yaml
        nodes:
          leaf1:
            kind: srlinux
            type: ixr-d2l # Change this to ixr-x1b
        ```

2. **Attempt deployment:**
    * Deploy the topology using the Containerlab CLI or VS Code extension.
    The deployment will fail, the `ixr-x1b` nodes will not start correctly due to the missing license.
    * Exited containers still exist, so destroy the deployment to clean up the environment. 

3. **Add the license:**
    * You can add the license using one of the following methods:
        * **Via VS Code extension:** If using the Containerlab VS Code extension, there is an option in the node's properties to add a license file.
        * **Directly in YAML:** Modify the `03-startup.clab.yml` file to include the `license:` keyword under the SR Linux node context, pointing to your license file.

            ```yaml
            nodes:
              leaf1:
                kind: srlinux
                type: ixr-x1b
                license: ./temporary-license.txt # Include relative or absolute path to the license
            ```

4. **Deploy with license:**
    * Deploy the topology again.
    * The deployment should now succeed, and the `ixr-x1b` node should start without issues.

5. **Verify node type:**
    * SSH into the `leaf1` node.
    * Execute the command `show version`.
    * The output should confirm that the node is running as an `ixr-x1b` type.
    * Execute the command `info from state system license` to verify the license status.

6. **Revert changes:**
    * Remove the license file and change the type back to `ixr-d2l` for the next tasks.

## Task 3b: Applying startup configurations

This task demonstrates how to automatically apply full startup configurations to network nodes upon deployment using the `startup-config` keyword in Containerlab.

1. **Reference configuration files:**
    * Open one of the configuration files located under `configs/`. Each line is a  `set` instruction that will be executed after deployment of the container. Containerlab will first preconfigure the container based on its kind - including SSH access, gRPC interfaces and specific filters. The configuration file is executed after this.
    * Edit the `03-startup-config.clab.yml` file. For each SR Linux node, add the `startup-config:` keyword under its context, pointing to its respective configuration file in the `configs/` directory.

        ```yaml
        nodes:
            leaf1:
              startup-config: configs/leaf1.cfg
              type: ixr-d2l
            leaf2:
              startup-config: configs/leaf2.cfg
              type: ixr-d2l
        ```

    * This can also be done via the Containerlab VS Code extension directly.

2. **Verify configuration (BGP session):**
    * Deploy the topology
    * SSH into one of the SR Linux nodes (e.g., `leaf1`).
    * Execute the command `show network-instance default protocols bgp neighbor`.
    * *Expected:* You should see that the BGP session between the two nodes is established and in an `Established` state, indicating the configuration was successfully applied.

---

## Task 3c: Applying full configurations

This task introduces the concept of applying full configuration to nodes, allowing for complete control on the configuration management. Containerlab will skip preconfiguration of the nodes, including injecting SSH keys. 

*Note:* The exact method for applying "full" or "partial" config can vary significantly based on the network operating system (NOS) and how Containerlab supports it. For SR Linux, partial config is done using SR Linux CLI format and full config is done using JSON format. 

1. **Add full configuration:**
    * Edit the `03-startup.clab.yml` file. Use `leaf1.json` as startup-config for leaf1.

        ```yaml
        nodes:
          leaf1:
            startup-config: configs/leaf1.json
            type: ixr-d2l
        ```

2. **Deploy and verify:**
    * Deploy the topology and try to SSH to leaf1. If the full config file has been applied, the node should ask you for a password to connect. This is proof that Containerlab did not preconfigure the node and only used the configuration file provided. To connect to the node, use the password `NokiaSrl1!`

## Task 3d: Adding Linux Containers with Bootup Commands

This task demonstrates how to integrate generic Linux containers into your Containerlab topology and execute specific commands automatically at bootup.

1. **Add a Linux container node:**
    * Edit the `03-startup.clab.yml` file and add a new node definition and a link with the following definition. You can achieve this directly within the extension or by manipulating the YAML file directly.

        ```yaml
        nodes:
          client1:
            kind: linux
            image: ghcr.io/srl-labs/network-multitool:latest
            exec:
              - ip address add 172.17.0.1/24 dev eth1
              - ip -6 address add 2002::172:17:0:1/96 dev eth1
        links:
          - endpoints: [ "client1:eth1", "leaf1:e1-2" ]
        ```

2. **Deploy and verify**
    * Deploy the topology SSH into the `client1` Linux container.
    * Check if the commands were executed using `ip addr show eth1`.
