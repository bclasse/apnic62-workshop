# Containerlab Workshop: Activity 1 - Basic topology management

This activity introduces fundamental Containerlab operations, including deploying single-node topologies, inspecting their configurations, modifying existing topologies by adding nodes and links, and optimizing topology definitions.

---

## Task 1a: Single node deployment and discovery

In this step, you will deploy a basic single-node topology, inspect the parameters configured by Containerlab during deployment, and understand the different `destroy` options.

1. **Check running Docker containers (before deployment):**
    * Execute `docker ps` to see currently running containers.

    ```bash
    docker ps
    ```

    *Expected:* You should not see any Containerlab-related containers running.
2. **Read the topology file:** Open 01-init.clab.yml and read the content of the file. What topology does this file describe ?

    *Answer:* A single-node topology running Nokia SR Linux version 25.10.1.
3. **Deploy the topology:**
    * Execute the following command to deploy the topology with Containerlab.

    ```bash
    containerlab deploy -t 01-init.clab.yml
    ```

4. **Check running Docker containers (after deployment):**
    * Execute `docker ps` again to observe the newly deployed Containerlab node(s).

    ```bash
    docker ps
    ```

    *Expected:* You should now see containers related to your `01-init.clab.yml` topology (e.g., `clab-01-init-leaf1`).
5. **Inspect created folder and files:**
    * Observe the `clab-01-init` directory created by Containerlab, containing configuration files and other deployment artifacts.
    * Execute `cat /etc/hosts` and observe the new entries added by Containerlab
6. **SSH into the node:**
    * Connect to the deployed `leaf1` node using the provided SSH command.

    ```bash
    ssh admin@clab-01-init-leaf1
    ```

7. **Inspect node configuration (inside the SSH session):**
    * **Check Version:** Verify the software version.

        ```bash
        show version
        ```

        *Expected:* The output should indicate a "D2L" type.
    * **Check interfaces:** List the network interfaces.

        ```bash
        show interface brief
        ```

        *Expected:* You should observe approximately 58 interfaces.
    * **Check management interface:** Verify the status and configuration of the management interface.

        ```bash
        show interface management
        ```

        *Expected:* The management interface should be up and configured.
    * **Check SSH keys:** Confirm that SSH keys have been populated for authentication.

        ```bash
        info system aaa authentication admin-user ssh-key
        ```

        *Expected:* You should see the SSH keys configured.
    * **Configuration change:** Execute the following commands to modify the system name.

        ```bash
        enter candidate
        system name host-name workshop
        commit save
        ```

        *Expected:* The system has been changed and visible on the prompt.
8. **Destroy the topology (without --cleanup flag):**
    * Exit the SSH session by typing `quit`, and destroy the Containerlab topology.

    ```bash
    containerlab destroy -t 01-init.clab.yml
    ```

    *Expected:* The Docker containers will be removed, but the `clab-01-init` folder and its contents will remain.
9. **Redeploy the node (without --reconfigure flag):**
    * Redeploy Containerlab topology.

    ```bash
    containerlab deploy -t 01-init.clab.yml
    ```

    *Expected:* The node is running again and is using the previous configuration file from the local `clab-01-init` folder.
10. **Destroy the topology (with cleanup):**
     * Execute the destroy command again, this time with the `--cleanup` flag.

     ```bash
     containerlab destroy -t 01-init.clab.yml --cleanup
     ```

     *Expected:* The `clab-01-init` folder including the previous configuration file has been removed. When redeploying the topology, no previous custom configuration should be visible.  

### Syntaxic sugars

Before moving to the next activity, it is worth noting that several shortcuts are available to shorten CLI commands for Containerlab.

* `containerlab` -> `clab`
* `deploy` ->  `dep`
* `destroy` ->  `des`
* `--cleanup` -> `-c`, used only with `containerlab destroy` to erase the artifacts folder associated.
* `--reconfigure` -> `-c`,  used only with `containerlab deploy` to redeploy a live topology from scratch.
* A typical command would end up being `clab dep -c` or `clab des -c`.
* When executing `clab dep` or `clab des` in a folder containing only one file with the .clab.yml extension, it is not necessary to refer to it with the `-t` flag. `clab dep` or `clab des` is enough to deploy or destroy the topology.

## Task 1b: Topology modification - adding nodes and links

In this step, you will modify the initial topology to add a second node and establish a link between the two nodes.

1. **Add a new node:**
    * Edit the `01-init.clab.yml` file.
    * Add a new node named `leaf2` with the same attributes (image, kind, etc.) as `leaf1`.
2. **Add a link:**
    * Uncomment the `links` section in the `01-init.clab.yml` file.
    * Modify the existing `endpoints` definition to connect `leaf1`'s `ethernet-1/1` interface to `leaf2`'s `ethernet-1/2` interface.
3. **Deploy the modified topology:**

    ```bash
    clab dep -t 01-init.clab.yml
    ```

    *Expected:* Two nodes (`leaf1` and `leaf2`) will be deployed, and a network link will be established between them.
4. **Verify connectivity**
    * SSH to leaf1 and execute the following command to verify LLDP neighbourship has been established

    ```bash
    show system lldp neighbor
    ```

    * If the link was configured properly, LLDP information about leaf2 should be displayed.

## Task 1c: Optimizing a topology using kinds

This task focuses on optimizing your topology definition by leveraging Containerlab's `kinds` feature to centralize common attributes.

1. **Custom an existing kind:**
    * Edit the topology file and add the following section under topology.

    ```yaml
      topology:
        kinds:
          nokia_srlinux:
            image: ghcr.io/nokia/srlinux:25.10.1
            type: ixr-d3l
    ```

    * This redefines what the kind `nokia_srlinux` means. It assigns a default image to the kind and overrides the default type used.
2. **Remove redundant attributes from the nodes:**
    * For each node (`leaf1`, `leaf2`), remove the `image` attribute, as it will now be inherited from the `nokia_srlinux` kind.
3. **Deploy, check, and destroy:**
    * Deploy the optimized topology:

        ```bash
        clab dep -t 01-init.clab.yml
        ```

    * SSH to one of the node and verify the version and type used by typing  `show version` on the CLI. The  `Chassis Type` field should now be set to  `7220 IXR-D3L` and the  `Software Version`, to  `v25.10.1`.

    * Once you're done, destroy the topology:

        ```bash
        clab des -t 01-init.clab.yml -c
        ```

---

## Task 1d: Understanding precedence with default kinds and node overrides

This task explores how Containerlab handles attribute precedence when `default` kinds are defined and specific attributes are overridden at the node level.

**Topology file:** `01-init-final-default.clab.yml`

**Steps:**

1. **Add a default kind:**
    * Edit the topology file and add the following section under topology.

    ```yaml
        topology:
          defaults:
            kind: nokia_srlinux
    ```

2. **Make use of the default kind**
    * For `leaf1`, remove every attribute defined under the node.
    * For `leaf2`, keep only the image definition and change the version number at the end of the image name. Set this value to 24.10.1 instead of 25.10.1.

3. **Deploy and observe precedence:**

    ```bash
    containerlab deploy -t 01-init.clab.yml
    ```

    *Expected:*
    * Attributes defined in the `default` kind will apply to nodes that don't specify a `kind`.
    * Attributes defined directly on a node (e.g., `image` for `leaf2`) will override attributes inherited from its `kind` or the `default` kind.
    * You can SSH into `leaf2` and check its version with `show version` to confirm the override.
    * Once you're done, destroy the topology:

        ```bash
        clab des -t 01-init.clab.yml -c
        ```
