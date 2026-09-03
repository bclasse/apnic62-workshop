# Introduction to SR Linux

This activity introduces fundamental SR Linux operations, including configuration change, state verification and logs reviewing.

---

## Single Node Deployment and Discovery

In this step, you will deploy a two-node topology, inspect and configure nodes, and observe logs.

**Topology File:** `srl-discovery.clab.yml`

**Steps:**

1. **Deploy the Topology:**
    * Execute the following command to deploy the topology with Containerlab.

    ```bash
    containerlab deploy -t srl-discovery.clab.yml
    ```

2. **Navigate the CLI and observe the configuration on each node:**
    
    SSH to each node to observe the configuration available. You will enter the running datastore on login. Execute the following command:

    ```bash
    info network-instance default

    info interface ethernet-1/1
    ```

    *Expected:* You should now see configuration related to the network instance `default` and the IP configured for interface `ethernet-1/1`.

3. **Ping the remote interface:**

    R1 and R2 are connected over a single link, ethernet-1/1 on each side. Try to ping the remote end by executing this command on R1.

    ```bash
    ping network-instance default 192.168.0.1
    ```

    *Expected outcome*: ping should be successful.

4. **On R1, execute those two commands to observe the state datastore:**
    ```bash
    info from state network-instance default protocols bgp neighbor

    show network-instance default protocols bgp neighbor
    ```

    * You should see that the BGP session is administratively disabled.
    * Both commands display state information: `info` reveals the YANG structure while `show` presents custom reports.

5. **Change configuration:**
    
    We will now enable administratively the BGP context on R1. Enter the candidate mode, enable it and commit the change.

    ```bash
    enter candidate

    network-instance default protocols bgp admin-state enable

    commit stay
    ```

6. **Inspect the BGP session state:**

    Repeat the state and show commands from step 3. After a few seconds, BGP should be up and the session with R2 should be established.
    
    
7. **Logs**

    Let's have a look at logs now.
    
* List available log files: To see the configured log destinations and their types (e.g., file, buffer), use the following command:

    ```bash
    show system logging
    ```

    *Expected output*: You will see a list of log IDs, their name and the directory where they are stored. File logs are persistent over reboot, buffer logs are not.

* View Log Buffer Content: To display the messages currently stored in the in-memory log buffer:

    ```bash
    show system logging buffer messages
    ```

    *Expected output*: This command will output a stream of recent log messages. You should be able to scroll through or search this output to find entries related to BGP.

    To quickly find relevant BGP messages, you can pipe the output through grep, just like you would on a Linux system:

    ```bash
    show system logging buffer messages | grep BGP
    ```

    *Expected output*: You should see messages similar to these, indicating the BGP session's state changes:

    ```
    2026-09-03T08:06:38.915 sr_bgp_mgr: bgp|8030|N: In network-instance default, the BGP session with VR default (1): Group ibgp: Peer 192.168.0.1 moved into the ESTABLISHED state...
    ```

    These messages confirm that the BGP session with your peer (192.168.0.1 in this example) has successfully transitioned to the Established state.

* Log files are located in a dedicated folder and can also be reached from the Linux underlying OS. Execute the following command to reach Linux and read the logs file in a different way:

    ```
    bash

    less /var/log/srlinux/file/messages
    ```
