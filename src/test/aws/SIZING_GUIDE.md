# k6 and PASOE Sizing Guide

This guide provides instance sizing recommendations and memory estimates based on empirical data
collected during multi-node load testing. All raw benchmark data, test run narratives, and
failure analysis have been consolidated here from initial working notes into a single reference.

---

## k6 Runner Node Sizing

### Per-VU Memory Model

Per Grafana documentation, each VU is allocated memory as part of its own JavaScript runtime
with the bytecode of the test and scenario information. All VUs are initialized at test start,
so peak memory occurs during the setup phase before sustained load begins. A VU may be
initialized but idle until it is ramped into active load by a test stage.

### Recommended k6 Runner Instance Types

| Instance Type | vCPU | Memory |
|---|---|---|
| r7a.large (AMD) | 2 | 16 GB |
| r7a.xlarge (AMD) | 4 | 32 GB |

> CPU is not the bottleneck for k6, but memory is the resource that requires headroom.

### Local and Docker Testing Context

Initial testing was performed inside a Docker container running under WSL on Windows 11. Early
test failures near ~800 VUs were caused by WSL's default 50% system memory cap (16 GB on a
32 GB host), not by k6 or the target server. Increasing the WSL memory limit to 24 GB resolved
this for 1,000 VU tests. The memory scaling behavior observed in WSL/Docker was nearly identical
to what was later confirmed on a dedicated AWS Linux server.

For local Docker testing, configure WSL memory via `%USERPROFILE%\.wslconfig`:

```ini
[wsl2]
processors=8
memory=24GB
swap=0
localhostForwarding=true
```

Run `wsl --shutdown` to apply the change. Verify with `cat /proc/meminfo` inside the container
or `docker stats` on the host.

**Additional notes from local and Docker testing:**

- The memory scaling behavior observed in WSL/Docker was nearly identical to a dedicated AWS
  Linux server (8 vCPU, 32 GB), confirming the per-VU estimates are environment-agnostic.
- CPU usage for k6 is highly efficient - an 8-core server remained at approximately 18%
  overall CPU utilization during a 1,000 VU test.
- Memory is the dominant system requirement. There is no way to avoid the per-VU JavaScript
  runtime allocation at test startup.

---

## PASOE Server Sizing

### MSAgent Configuration

Each MSAgent hosts a fixed number of ABL sessions (50 per agent in these tests). PASOE starts
agents on demand as load increases. The key configuration concern is the initial agent count.

**Critical:** Configure PASOE to pre-start at least 50% of the maximum agent count. When agents
start from zero on demand, the scale-out event happens mid-test under full load - observed as a
burst of server-side errors and a distinct throughput interruption in the k6 console. A second
run at 2,000 VUs with 50% pre-start avoided this entirely.

### Tomcat Executor Threads and Java Heap

The Tomcat executor thread count is the server-side concurrency ceiling. VU counts above the
thread limit increase backend pressure but not throughput.

- Effective concurrency plateaued at ~990 clients when the thread limit was 1,000.
- Increasing threads to 2,000 caused PASOE to start additional MSAgents up to the configured
  maximum.
- At 5,000 threads with the default Java heap, heap exhaustion halted request handling mid-test.
  The heap must be explicitly sized when raising executor threads.

### Observed Server Behavior by Test Scale

| Total VUs | Nodes | Executor Threads | Java Heap | MSAgents | Instance Type | Memory Used |
|---|---|---|---|---|---|---|
| 2,000 | 2×1K | 1,000 | Default | 3 of 6 | c7i-flex.4xlarge | ~16 GB of 30 GB |
| 3,000 | 3×1K | 2,000 | Default | 6 of 6 | c7i-flex.4xlarge | ~29 GB of 30 GB |
| 5,000 | 5×1K | 5,000 | 8 GB | 4 of 20 | c7i-flex.16xlarge | ~9.5 GB Java + 4×~5.2 GB agents |

> At 3,000 VUs the server used ~29 GB of 30 GB - effectively no safety margin. A larger
> instance type is advisable for sustained tests at this scale.
>
> The 5K test reached peak load with only 4 of 20 MSAgents active. This indicates the PASOE
> instance handled 5,000 concurrent connections with 200 ABL sessions (4 agents × 50 sessions)
> and approximately 20.8 GB of agent memory, with Java itself at 9.5 GB.

### Multi-Node Test Run Details

#### 2K Test - 2 Nodes @ 1K VUs Each

This was the initial validation of a multi-node, simultaneous approach to confirm that a
distributed client setup would work as expected. Both nodes were clones of the same AMI and
configured for 1,000 VUs each - the most comfortable fit for a 32 GB runner instance.

Notably, despite a combined 2,000 VUs across both nodes, PASOE never started more than 3
MSAgents. The 1,000 executor thread limit was the effective ceiling, not the agent count.

#### 3K Test - 3 Nodes @ 1K VUs Each

The primary change for this test was increasing the Tomcat executor threads to 2,000 - higher
than the DMSi reported value of 1,400. The direct result was that PASOE started additional
agents up to the full maximum of 6, consuming nearly the entire 30 GB of server memory with
only ~1 GB to spare. This left no meaningful safety margin and highlighted the need for a
larger instance at this scale.

#### 5K Test - 5 Nodes @ 1K VUs Each

The PASOE server was scaled to a `c7i-flex.16xlarge` (64 vCPU, 128 GB) and the maximum
MSAgent count was raised to 20 - matching configurations seen with DMSi - with 50 sessions
per agent for a theoretical maximum of 1,000 ABL sessions. Calculated memory at full capacity
would be approximately 120 GB (20 agents × ~5 GB each).

On the first run, requests stopped near peak load due to Java heap exhaustion - the Tomcat
server had not been configured for the increased executor thread count. The heap was explicitly
set to 8 GB as part of the build process, and sane defaults for related values were derived
alongside it.

**Final results (successful run, 60 minutes):**

| Milestone | Time | Total VUs | Java Heap | MSAgents (Memory Each) |
|---|---|---|---|---|
| Midpoint (500 VUs/node) | ~27 min | 2,500 | 8.6 GB | 4 agents: 5.2, 4.8, 4.8, 4.8 GB |
| Peak (1,000 VUs/node) | ~50 min | 5,000 | 9.2 GB | 4 agents: 5.3, 5.2, 5.2, 5.2 GB |
| End of run | ~60 min | 5,000 | 9.5 GB | 4 agents: 5.3, 5.2, 5.2, 5.2 GB |

The run completed without incident. Only 4 of the 20 configured MSAgents were needed to handle
5,000 concurrent connections, indicating substantial headroom remains in the server configuration.

### Recommended PASOE Instance Types

| Total VUs (all nodes) | Recommended Type | vCPU | Memory | Max MSAgents |
|---|---|---|---|---|
| Up to 2,000 | c7i-flex.4xlarge | 8 | 32 GB | 6 @ 50 sessions |
| Up to 3,000 | c7i-flex.4xlarge | 8 | 32 GB | 6 @ 50 sessions (tight) |
| Up to 5,000 | c7i-flex.16xlarge | 64 | 128 GB | 20 @ 50 sessions |

---

## PASOE Server Testing

The following reflects what was observed on the PASOE target server across the multi-node test
runs documented in this guide. This is not a PASOE configuration guide - it is a record of
how the server behaved under increasing load so that results can be understood in context.

### What Was Observed

Each MSAgent hosted 50 ABL sessions. PASOE started agents on demand as load increased, but
auto-scaling consistently lagged behind demand during ramp-up. On the first 2K VU test a third
MSAgent was triggered around the ~1,600 VU mark, causing a burst of server-side errors and a
visible throughput interruption. Only 28 of 50 sessions on that agent initialized before the
test terminated - not enough warm-up time under full load. Configuring PASOE to pre-start 50%
of the maximum agent count eliminated this on a second run.

The Tomcat executor thread count proved to be the server-side concurrency ceiling. Effective
concurrency plateaued at ~990 clients with a 1,000 thread limit regardless of VU count.
Raising threads to 2,000 caused PASOE to start additional agents up to the maximum. At 5,000
threads with the default Java heap, heap exhaustion halted request handling mid-test - the heap
must be explicitly sized when raising executor threads significantly.

Database record locking on the test tables was a persistent bottleneck. Locked records
increased request latency, which extended VU lifetimes, which amplified memory consumption on
both the runner nodes and the server.

### Server Behavior by Test Scale

| Total VUs | Nodes | Executor Threads | Java Heap | MSAgents | Instance Type | Memory Used |
|---|---|---|---|---|---|---|
| 2,000 | 2×1K | 1,000 | Default | 3 of 6 | c7i-flex.4xlarge | ~16 GB of 30 GB |
| 3,000 | 3×1K | 2,000 | Default | 6 of 6 | c7i-flex.4xlarge | ~29 GB of 30 GB |
| 5,000 | 5×1K | 5,000 | 8 GB | 4 of 20 | c7i-flex.16xlarge | ~9.5 GB Java + 4×~5.2 GB agents |

**2K test:** Despite 2,000 combined VUs across two nodes, PASOE never started more than 3
agents. The 1,000 executor thread limit was the binding constraint, not the agent count.

**3K test:** Raising threads to 2,000 (above the DMSi-reported value of 1,400) caused all 6
agents to start, consuming ~29 GB of the available 30 GB - essentially no safety margin.

**5K test:** Scaled to a `c7i-flex.16xlarge` (64 vCPU, 128 GB) with a maximum of 20 agents.
On the first attempt heap exhaustion stopped the server near peak load. After setting the heap
explicitly to 8 GB the second run completed without issue. Only 4 of 20 agents were needed to
handle the full 5,000 VU load, indicating substantial headroom in the server configuration.

**5K final run progression (60 minutes):**

| Milestone | Time | Total VUs | Java Heap | MSAgents (Memory Each) |
|---|---|---|---|---|
| Midpoint (500 VUs/node) | ~27 min | 2,500 | 8.6 GB | 4 agents: 5.2, 4.8, 4.8, 4.8 GB |
| Peak (1,000 VUs/node) | ~50 min | 5,000 | 9.2 GB | 4 agents: 5.3, 5.2, 5.2, 5.2 GB |
| End of run | ~60 min | 5,000 | 9.5 GB | 4 agents: 5.3, 5.2, 5.2, 5.2 GB |

### Anomalous MSAgent Scaling at 5K

The most counterintuitive finding across all test runs is that the 5K test - with double the
VUs and more than double the executor threads of the 3K test - started *fewer* MSAgents and
did so with significant headroom remaining on a much larger server.

| Test | VUs | Executor Threads | Java Heap | Agents Started | Server Memory |
|---|---|---|---|---|---|
| 3K | 3,000 | 2,000 | Default | **6 of 6** (maxed out) | ~29 GB of 30 GB |
| 5K | 5,000 | 5,000 | 8 GB | **4 of 20** (20% of max) | comfortable |

This is not explained by load alone. Two contributing factors are likely:

**1. The Tomcat thread pool acted as an absorption buffer.**
With 5,000 threads available, Tomcat could hold a far larger number of in-flight HTTP requests
internally before needing to dispatch them to ABL sessions. At 3K with only 2,000 threads, the
Tomcat layer saturated quickly - requests could not queue and PASOE was forced to spin up
additional agents to drain the backlog. With 5,000 threads, incoming requests are absorbed and
paced into the ABL layer more gradually, reducing the apparent demand signal for new agents.

**2. Explicit heap sizing changed JVM scheduling behavior.**
The default Java heap was insufficient even at 3K scale, meaning the JVM was likely under
constant GC pressure during that test. Frequent garbage collection causes stalls, which cause
ABL sessions to appear unavailable momentarily, which triggers PASOE to compensate by starting
more agents. With the heap explicitly set to 8 GB, GC pressure was reduced, sessions cycled
more smoothly, and PASOE had no reason to provision additional agents.

**The key implication** is that MSAgent spawn behavior is not driven by VU count - it is driven
by ABL session saturation, which is itself a function of how quickly Tomcat can absorb and
drain requests. The 3K test hit a convergence of pressure points: enough VUs to saturate,
insufficient threads to buffer, and an undersized heap amplifying the problem through GC
interference. Correcting the thread count and heap independently may have each reduced agent
demand; correcting both together appears to have reduced it dramatically.

This warrants further investigation with controlled tests varying thread count and heap size
independently to isolate which factor has the greater influence on agent scaling behavior.

**Next Steps**
A straightforward next test would be to hold all 5K conditions constant (same instance type,
same 8 GB heap, same agent configuration) and increase VUs beyond the 5,000 executor thread
ceiling. If agent count rises once requests can no longer be absorbed by the Tomcat thread pool,
that confirms thread pool saturation as the primary driver of agent scaling. If agent count
remains flat even under that additional pressure, the heap and GC theory becomes the stronger
explanation. **UPDATE** Executing a test with a total VU count of 10K finally drove the PASOE instance to start more MSAgents, up to the max of 20. This occurred close to the peak load--above 5,000 but not quite at 10,000 active VUs. Oddly, the spike in new MSAgents seemed to happen nearly all at once and not in a minimal or controlled fashion as might be expected.


### Guidance and Suggestions

**Mike J.**: The Tomcat server has multiple levels of client request buffering:

* The Http/https TCP connector buffers inbound client requests and can return an error to a client if it cannot respond in time due to lack of CPU/memory.
* The Tomcat Service’s executor pool of threads governs the maximum # of concurrently executing client requests across ALL web applications. There is an overflow queue, but the time a request can be in a queue is limited. If single web app, or web apps, has emptied the executor thread pool your ABL web app may cease to function until those other web apps free up executor threads. An executor thread is locked to a single client request until the web app it is executing has terminated with an error or its [ABL Session] has written its request’s response.  
* Setting the executor thread pool size larger does not increase the ABL application’s request capacity unless all deployed web apps are mapped to that ABL application.

The ABL application’s concurrent ABL request capacity is determined by the smaller of: `# MS-Agent connections * # MS-Agents` or `# max ABL Sessions * # MS-Agents`.
The # of MS-Agents will scale up on demand. Scaled MS-Agents to handle short-duration client request spikes and then remain idle thereafter become memory and database connection boat anchors of no value.

With your configuration of 2,000 executor threads feeding 50 TCP connections per MS-Agent and a max of 6 agents, it gives you a maximum ABL request concurrency of 300.  Doesn’t that mean that you are wasting 1700 Executor threads that just eat memory while queue up in the SessionManager.  Is that really what you want?

The Tomcat executor thread pool (shared by all web apps) and an ABL application’s SessionManager pool of MS-Agents and their TCP network connections are independent subsystems. They cannot be linked together as a single unit to adjust concurrent request capacity.
The default JVM heap size is akin to tossing a dart at a target in a pitch-black room. There must be a value, but it has no guarantee that your PASOE configuration will operate efficiently (if at all…). It is one of the constant monitoring points with notifications and trend analysis. 

The VU count has zero (0) impact on anything. All web application servers are configured and scaled to handle concurrent request capacity consumption of CPU, memory, and I/O. The # of client connections is irrelevant because they constantly are created, terminated, and recreated. You can relate the # of clients to JVM memory consumption for stateful http session storage, which reduces the amount available for executing requests.  Capacity is controlled by coordinating the executor thread pool with the maximum ABL application’s MS-Agent connection and ABL Session Pool sizes.


**Dave C.**: Have you played around with this property at all?

    connectionWaitTimeout=3000
        Maximum amount of time, in milliseconds, that session manager will wait
        for a connection to be freed up before creating a new connection

This will wait 3 seconds by default to wait for a connection to be freed before starting up a new agent. I can see garbage collection triggering this timeout and may be why you see the results below. Set it to 1000 and see what happens.


**Dave M.**: While I’m only a virtual member of the Topcat team, I have a couple comments.

1. You should be able to validate AI’s suspicion #2 by trying the 3K test with 8 GB and seeing if you get 3K behavior again or something closer to 5K behavior.
    * 3K behavior would suggest Tomcat’s absorb/drain rate is the bottleneck
    * 5K behavior would suggest heap size is the bottleneck
    * Something in between suggests both are at play
2. AI suspicion #1 sounds feasible to me and you may have uncovered an interesting optimization our customers could potentially utilize on high external traffic applications which further testings on the above might reveal further.
