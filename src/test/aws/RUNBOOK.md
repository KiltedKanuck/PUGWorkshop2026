# Multi-Node k6 Test Execution Runbook

This runbook covers the end-to-end procedure for executing a coordinated multi-node load test
using the OELS k6 test suite on AWS EC2 runner nodes.

---

## Prerequisites

Before beginning, confirm all of the following:

- [ ] k6 runner EC2 instances are running  
      _(see [AWS_K6_AMI.md](AWS_K6_AMI.md) to launch new instances from the AMI)_
- [ ] Each runner has the latest OELS test archive installed  
      _(see [AWS_K6_SETUP.md](AWS_K6_SETUP.md) for full setup instructions)_
- [ ] PASOE target server is running and accepting connections
- [ ] PASOE Tomcat executor thread count is appropriate for the planned total VU count  
      _(see [SIZING_GUIDE.md](SIZING_GUIDE.md))_
- [ ] PASOE initial MSAgent count is set to at least 50% of the configured maximum  
      _(failure to do this causes a mid-test scale-out disruption and a burst of errors)_
- [ ] Java heap size on the PASOE server has been explicitly configured  
      _(default heap is insufficient at high executor thread counts)_
- [ ] Each runner's test config file points to the correct target server address and VU count

---

## Test Planning

Total effective load is the product of per-node VUs and the number of nodes:

```
Total VUs = (VUs per node) × (number of nodes)
```

For example: 5 nodes × 1,000 VUs each = 5,000 total VUs against the PASOE server.

Verify the planned total against the [SIZING_GUIDE.md](SIZING_GUIDE.md) to confirm both runner
node and PASOE server instances are appropriately sized before proceeding.

---

## Node Access Setup

k6 has no native cluster controller - each runner node operates as an independent process.
Coordinating a multi-node test means connecting to each node, staging the launch command, and
starting them within a narrow window. The key to doing this efficiently is having fast, named
SSH access to every node from your local machine before the test begins.

### Tracking Node IP Addresses

AWS assigns a new public IP each time an EC2 instance is started. Before each test session,
collect the current public IP for every runner node from the EC2 console. The node names are
consistent (OELS-K6-Runner-1 through -5) but the IPs change each session.

### SSH Config on Windows

The Windows SSH client (available in PowerShell and Windows Terminal) reads a config file at
`%USERPROFILE%\.ssh\config`. Defining a named host entry per node lets you type
`ssh k6-node-1` instead of managing IP addresses, usernames, and key paths on every command.
This is especially useful when you need to open multiple terminal tabs in rapid succession
before starting a test.

**Sample `%USERPROFILE%\.ssh\config`:**

```
# Shared defaults for all OELS nodes - applied to any Host entry below that
# does not override them. Must appear before the individual Host entries.
Host oels-pasoe k6-node-*
    User ubuntu
    IdentityFile ~/.ssh/loadteam.pem
    ServerAliveInterval 60

# OELS PASOE Target Server
Host oels-pasoe
    HostName <pasoe-public-ip>

# OELS k6 Runner Nodes - update HostName values each session from the EC2 console
Host k6-node-1
    HostName <node-1-public-ip>

Host k6-node-2
    HostName <node-2-public-ip>

Host k6-node-3
    HostName <node-3-public-ip>

Host k6-node-4
    HostName <node-4-public-ip>

Host k6-node-5
    HostName <node-5-public-ip>
```

> `ServerAliveInterval 60` sends a keepalive packet every 60 seconds so the connection stays
> open for the full duration of a long test without being dropped due to inactivity.

With this in place, update only the `HostName` values each session and connect to any node with:

```
ssh k6-node-1
```

Windows Terminal supports opening multiple tabs from the command line or profile shortcuts,
making it straightforward to have all node sessions ready before starting a test.

---

## Execution

### 1. Open an SSH session to each runner node

Open a separate terminal tab per node using the named aliases from the SSH config above.
Have all sessions ready before starting any test - coordinated start timing is important
since k6 has no native cluster synchronization.

### 2. Stage the test command on each node

On each node, navigate to the tests directory and prepare the launch command without executing it:

```bash
cd tests

# Stage the command - do not press Enter yet
./launchUnifiedScenario.sh configs/<your-config>.json
```

For a live dashboard and saved HTML report, append `-useDashboard`:

```bash
./launchUnifiedScenario.sh configs/<your-config>.json -useDashboard
```

For raw metric capture (produces large files - use only when needed):

```bash
./launchUnifiedScenario.sh configs/<your-config>.json -includeJsonResults
```

> See `src/test/framework/k6/docs/README.md` for the full list of available launchers and flags.

### 3. Start all nodes as close together as possible

Execute the staged command on each node in rapid succession. Tight manual timing within a few
seconds is sufficient for meaningful load pattern alignment. There is no synchronization barrier;
just start each node before the ramp-up on the first node has progressed significantly.

### 4. Monitor the run

**On the PASOE server**, watch for:

| Metric | What to Watch For |
|---|---|
| Java heap usage | Heap exhaustion - especially at high executor thread counts |
| MSAgent count and per-agent memory | Confirm agents start as expected; watch for scale-out events |
| Active HTTP connections | Should track toward the executor thread limit at peak load |

**On each k6 runner node**, the k6 console reports in real time:

| Output | Meaning |
|---|---|
| `VUs` | Currently active virtual users |
| `http_reqs` | Request rate |
| `http_req_failed` | Error rate - should remain near zero under normal conditions |
| `http_req_duration` | Response time percentiles - rising p95/p99 indicates backend pressure |

### 5. Watch for known failure modes

| Symptom | Likely Cause | Action |
|---|---|---|
| Burst of errors mid-test | MSAgent scale-out lag | Pre-start 50% of max agents before next run |
| k6 process stalls or hangs | Runner node out of memory | See [SIZING_GUIDE.md](SIZING_GUIDE.md) for instance sizing |
| Request rate plateaus below VU target | Executor thread limit reached | Increase Tomcat executor threads |
| Java heap errors on PASOE | Heap too small for thread count | Increase `-Xmx` in proportion to thread count |
| High latency / lock-related errors | Database record contention | Expected under high load; monitor but not necessarily a failure |

### 6. Post-run

After the test completes, results are automatically saved to the `logs/` directory on each
runner node with a timestamped filename:

```
logs/results-<testname>-<timestamp>.json
```

Log collection and result aggregation across nodes will be handled by dedicated scripts.

---

## Reference

| Document | Purpose |
|---|---|
| [README.md](README.md) | Architecture overview and component descriptions |
| [AWS_K6_AMI.md](AWS_K6_AMI.md) | Launching runner instances from the shared AMI |
| [AWS_K6_SETUP.md](AWS_K6_SETUP.md) | Full runner OS and software setup from scratch |
| [SIZING_GUIDE.md](SIZING_GUIDE.md) | Instance sizing, memory benchmarks, and multi-node test results |
