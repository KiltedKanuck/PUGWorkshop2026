# User Load Workflow

- [The k6 Client](#the-k6-client)
- [The PASOE Server](#the-pasoe-server)
- [Telemetry and Diagnostics](#telemetry-and-diagnostics)

## The k6 Client

Given a potential user load of 10,000 virtual users (10K VUs) the first decision is in how to break up the workload. This can only be determined by executing tests, observing the system state by the end of a test, and adjusting accordingly.

### Node Sizing Options

Execution of k6 tests should be considered a 1:Many type approach, where an execution is considered a "node" within a potential cluster of client instances which all utilize the same target server (PASOE application).

- 1 x 10,000 VUs
- 2 x 5,000 VUs
- 5 x 2,000 VUs
- etc.

#### Node Resource Considerations

- Runtime Overhead
   - MB per VU - Observe at start vs. end of test runs
- Network Capacity
   - AWS Costs - Consider compute costs plus network throughput

### k6 Data Contracts

In order to drive tests at scale there is a need for a suitable pool of data. This involves creating synthetic records for the application tables in a way that the k6 tests can be guaranteed to know a record exists without actually knowing the primary keys. Both the server and client would need to use the same patterns for key fields.

- Sequence Keys: Use a standard next-value() in ABL on each create of a record.
- Natural Keys: Use a custom prefix + PK field name + an incremented count.
- Date Keys: Use a custom epoch date (2025-12-31) adjusted by record number as added minutes.

### k6 Profile Choice

Test capacity within k6 is driven primarily by duration and VU counts, though the usage of those parameters is driven by what we have called "profiles". A set of standardized profiles exist as "smoke", "load", "stress", and "chaos" which range from 1:1 sanity tests to potentially unbound behaviors. However, in order to compare results in a somewhat controlled manner we must balance variability with determinism.

**Recommended:** "stress" which is a form of [Soak Test](https://en.wikipedia.org/wiki/Soak_testing) which applies constant traffic against the test target.

**Why?** Applies a controlled, progressively ramped pressure against the server. Provides a randomized, controlled pattern for effective [A/B Testing](https://en.wikipedia.org/wiki/A/B_testing).

#### Stress Profile - Ramped Stages

The duration of the test is divided into 5 stages, the first 4 are evenly divided while the final may either be equal or the remainder of that calculation. Meanwhile, the VU load will be split among the first 4 stages to ramp up 1/4 (25%) of the VU load by the end of each stage.

1. Warmup
   - First 1/4 of VU load
   - Find first failures, opportunity to end early
   - Determine bug vs environment issue
2. Ramp 1
   - Next 1/4, 50% of VU load
   - Watch and react
3. Ramp 2
   - Next 1/4, 75% of VU load
   - Continues increasing load
4. Peak
   - Final 1/4 to 100% of VU load
   - Learning phase!
   - Observe bottlenecks
5. Cooldown
   - Removes VUs until none are running
   - Measure recovery of PAS and server

One important thing to remember is that k6 will start up a runtime for all VUs at the start of the test, but they will not begin consuming memory until they are executed. This means that every group of VUs started per stage will continue to run with repeated iterations until the final stage where VU load is reduced.

VU Lifetimes:
```
1 |===========|...
2    |========|...
3       |=====|...
4          |==|...
```

#### Post-Run Analysis

Stages 4 & 5 provide the most opportunity to summarize and adjust as necessary post-execution:

- Memory Growth = End - Start
- Review for Failures
  - What?
  - Where?
- Next Run Adjustments

### Virtual User Behavior

k6 Allocation / Ready Phase:
- 5K VUs = 5K runtimes and initial memory allocations
- Baseline memory sizing (see "Node Sizing Options")
- Node sizing validation using post-execution data

Workload Per Stage:
- VU AuthN (OERealm)
   - No DB, all are welcome (not meant to be a bottleneck)
- Do Work: API Calls (PASOE)
   - CRUD = DB-heavy (high % of requests)
   - NOOP = CPU-oriented (low % of requests)
   - Randomized workload selection among each
- Wildcards
   - 15 minute session expiration
   - Anomaly testing (eg. issue a QUIT/STOP statement)

## The PASOE Server

The PASOE instance is the sole driver of the API layer, supporting both as a web server and OpenEdge AVM environment, and manager for the attached database.

1. Tomcat Starts (`tcman oeserver start`)
   - Executes Lifecycle Scripts
   - Database Startup
   - Sets Environment Variables
2. Session Manager Starts
   - Spawns initial MSAgent(s)
   - MSAgent(s) start initial ABL Sessions
      - ABL Sessions prepare database connection info
      - ABL Sessions start a DOH Event Handler singleton
         - Reads all `.map` files for available services
      - ABL Sessions connect to the database

**Success Criteria:** 100% started with no Java or OpenEdge errors.

### Limiting Factors

For every request the available throughput depends on several factors which act as a funnel into the OpenEdge runtime (AVM):

```
Tomcat
   -> Executor Threads (and Timeouts)
   -> Java Heap Size (per Thread)
      -> The lesser of [MSAgents x Sessions] or [MSAgents x Connections]
         -> Database Connections
```

### Runtime Sizing

**Formula:** Σ DB Connections = Σ ABLApps [ (Agents x Sessions) + Agents ]

Example:
```
   5 Apps x 20 Agents x 50 Sessions  = 5,000  (PASN Connections)
   5 Apps x 20 Agents                =   100  (PASA Connections)
                                     = 5,100  (Total DB Connections)
```

> In the OELS testing we only utilize a single ABL Application with 20 MSAgents, which is why the user count against the database is at most 1,020. Customers who utilize multiple ABL Applications with variable min/max MSAgent values would produce widely varying counts.

### API Handling (DOH Events)

#### Service Discovery

- Session Startup (runs once)
- Pre-load Service Registry
   - Data (CRUD) Services
   - Object/Procedure Services
   - Anomaly Services

#### Invoking (Entity)

- Establish User Identity
   - Obtain CPO
   - set-db-user()
   - Create/Update Session Context
- Load Entity
   - Find requested ABL class/procedure
   - Prepare ABL code for requested service

#### Invoked (Entity)

- Execute Code
   - Result: Success (incl. structured errors)
   - Result: Operation Error (unhandled)
- Perform Cleanup
   - Reset User's CPO
   - Update Session Context

## Telemetry and Diagnostics

Each k6 test iteration captures data which is contributed to metrics for the overall test profile, reported via a custom `summary.txt` document.

- HTTP Status - Checked as per-iteration sanity test
- JSON Body - Checked as per-iteration sanity test
- Response Headers
   - Unique Request ID - Reported with errors
   - Agent PID + Session ID - Reported with errors
   - ABL Duration - Tracked as overall min/max/avg.
- Request-Response Duration - Tracked as overall min/max/avg.

### Root Cause Attribution

Use the available metrics from the k6 summary and/or application logs to determine potential causes.

**Example:** By using the ABL Duration and Request-Response Duration it may be possible to identify certain bottlenecks within the application.

- **ABL Duration < Request-Response Duration**
   - Significant differences in time indicate a potential problem within Tomcat or the Session Manager while finding a suitable ABL Session to execute the code.
- **ABL Duration ≈ Request-Response Duration**
   - Nearly matching values indicate ABL execution is the predominant factor, but excessive time overall may indicate system stress due to DB tuning, code efficiency, lock contention, etc.
