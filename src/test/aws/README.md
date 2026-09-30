# AWS Multi-Node k6 Load Testing

This directory contains documentation and supporting scripts for deploying and operating a
multi-node Grafana k6 load testing environment targeting an OpenEdge PASOE server in AWS.

---

## Architecture

A multi-node test uses multiple EC2 instances running k6 in parallel against a single PASOE
target server. Each k6 runner operates independently - there is no native k6 cluster
coordination - so tests must be started manually (or scripted) within a narrow window to
achieve meaningful simultaneous load.

```
  [ k6 Runner Node 1 ]──┐
  [ k6 Runner Node 2 ]──┤
  [ k6 Runner Node 3 ]──┼──► [ PASOE Server ] ──► [ MSAgent 1..N ] ──► [ Database ]
  [ k6 Runner Node 4 ]──┤
  [ k6 Runner Node 5 ]──┘
```

### k6 Runner Nodes (EC2)

- Each node runs an independent k6 process executing the OELS test scripts.
- Nodes are provisioned from a shared AMI to ensure consistent OS, tooling, and test versions.
- Each node contributes its configured VU count to the total concurrent load on the target server.
- Memory is the primary resource constraint - CPU utilization remains low even at 1,000 VUs.

### PASOE Server (EC2)

- Progress Application Server for OpenEdge - the HTTP entry point for all k6 requests.
- Routes requests to MSAgent instances which execute ABL business logic.
- The Tomcat executor thread count is the effective ceiling on concurrent HTTP requests regardless
  of how many VUs are active across the runner nodes.

### MSAgents

- Managed server agents started on demand by PASOE in response to incoming load.
- Each agent hosts a fixed number of ABL sessions (typically 50 per agent).
- Agent count and per-agent memory footprint are the primary server-side scaling constraints.
- Auto-scaling lags behind demand - configure PASOE to pre-start at least 50% of the maximum
  agent count to avoid a burst of server-side errors mid-test during a scale-out event.

### Database

- Backend OpenEdge database accessed by ABL sessions within each MSAgent.
- Record locking and table contention directly affect request latency, which in turn extends
  the lifetime of active VUs and amplifies memory consumption on both sides of the test.

---

## Key Observations

A few critical findings that inform all sizing and execution decisions:

- **k6 runner memory is the primary constraint**, not CPU. Each VU requires approximately
  20–30 MB under sustained load. See [SIZING_GUIDE.md](SIZING_GUIDE.md) for full breakdowns.
- **MSAgent auto-scaling lags under load.** Pre-starting agents prevents mid-test disruption.
- **Database contention is the server-side bottleneck.** Locking raises latency, which extends
  VU lifetimes and amplifies memory usage on runners and server alike.
- **Effective concurrency plateaus at the Tomcat thread limit.** Additional VUs beyond that
  threshold increase pressure but not throughput.
- **Java heap must be scaled with executor thread count.** Default heap is insufficient at
  high thread counts - a heap exhaustion failure was observed at 5,000 threads.

---

## Contents

| File / Folder | Purpose |
|---|---|
| [README.md](README.md) | This file - architecture overview and index |
| [AWS_K6_AMI.md](AWS_K6_AMI.md) | Launching a new k6 runner EC2 instance from the shared AMI |
| [AWS_K6_SETUP.md](AWS_K6_SETUP.md) | Full OS and k6 software setup for a fresh EC2 instance |
| [SIZING_GUIDE.md](SIZING_GUIDE.md) | Client and server instance sizing recommendations |
| [RUNBOOK.md](RUNBOOK.md) | Step-by-step multi-node test execution procedure |
| [SWAPFILE.md](SWAPFILE.md) | Configuring an emergency swap file on a runner node |
| [EARLYOOM.md](EARLYOOM.md) | Installing the earlyoom out-of-memory watchdog on a runner node |
| [bin/mkswap.sh](bin/mkswap.sh) | Script to create and activate the swap file |
| [fargate/](fargate/README.md) | Planned Fargate-based container deployment architecture (in progress) |
