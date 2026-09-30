# Multi-Scenario Test Notes

The individual k6 test scripts were created to allow testing of specific API's in isolation. Each test is responsible for creating and deleting any dependencies required for operation, though this is primarily needed for the CRUD type tests. These tests are capable of running in simplistic 1-shot (smoke/simple) configurations to validate feasibility or run in a specific profile such as load (constant) or stress (ramping) which alters the Virtual Users (VUs) involved. Another profile allows for more chaos (randomized) behavior using randomized stages of stress. In all cases these individual scenarios involve their own pool of executors.

## Problem and Goal Summary

The chaos launcher unintentionally created far more parallel concurrency than expected because k6 allocates VUs per scenario, which saturated ABL connection capacity and surfaced as auth-related failures. The goal is to keep load testing realistic and repeatable by matching test concurrency design to server limits, while preserving standalone constant-vus and ramping-vus patterns per script.

## Expectation Drift Summary

| Original Expectation | K6 Reality | Faulty Outcome |
|---|---|---|
| Multi-scenario launcher uses one shared VU pool | Each scenario has its own VU pool | Total concurrency summed across scenarios and spiked higher than expected |
| Per-scenario cap was enough to control load | Aggregate cap is what matters most | Server was oversubscribed even when each scenario looked individually reasonable |
| Auth errors implied credential problems | Logs show connection reservation failures first | Capacity failure was misread as auth failure |
| Staggering start times would fully control overload | Staggering only softens startup burst | Sustained overlap still saturated backend resources |

## Load Vs Capacity

| Test/Config Value | Server/Platform Value | Faulty Outcome |
|---|---|---|
| Scenario count: 45 | Max agents: 2 | Too few agent pools for combined parallel demand |
| Max VUs per scenario: 20 | Max ABL sessions per agent: 120 | Potential max VUs far exceeded practical backend concurrency |
| Theoretical max VUs: 45 x 20 = 900 | Backend connection ceiling: about 2 x 120 = 240 | About 3.75x oversubscription potential |
| Observed unique VU IDs: about 527 | Tomcat executor threads: 600 | Front-door concurrency could queue more work than ABL pool could serve |

## What Logs Confirmed

| Signal | Interpretation |
|---|---|
| timeout error occurred while reserving a connection | Session manager could not acquire backend connection in time |
| No Available Connections [cannot start new agent] | Pool exhausted and expansion path was blocked by limits |
| OERealm username load and user authn errors | Realm bridge failed after connection reservation failures |
| Bad credentials in fail-success mode | Error mapping symptom, not true credential rejection |

## Desired Test Pattern

| Goal | Preferred Pattern |
|---|---|
| Controlled repeatable pressure | Standalone script with constant-vus |
| Realistic growth and decline | Standalone script with ramping-vus |
| Mixed workload under one global cap | Single-scenario composite launcher with weighted operation dispatch |

## Intended Outcome and Design Rationale

**Business Goal:** Stress-test the OpenEdge/PASOE application server and underlying database under realistic user load to validate feasibility of specific server configurations and identify code path bottlenecks.

**Why Single-Pool Composite Launcher:**

1. **Controllable Concurrency for A-B Testing** - A single VU pool with global cap (e.g., 240 concurrent users) enables reliable A-B testing across server/database configurations. Current multi-scenario approach creates uncontrollable aggregate load (45 scenarios × 20 VUs = 900 potential) incompatible with reproducible benchmarking.

2. **Realistic Mixed Workload** - Real users authenticate once, then execute varied operations (read, create, update, stress-specific-path) while maintaining session. Each k6 VU simulates one user session, not 45 parallel scenario pools hammering individual tables uniformly. Weighted operation dispatch distributes load authentically (e.g., 30% CRUD, 25% read-heavy, 25% write-heavy, 20% targeted stress).

3. **Deterministic Ramp Analysis** - Linearly ramping from low → high concurrency (e.g., 50%, 75%, 100% of backend capacity) captures server/database behavior curve, revealing throughput limits, saturation point, and degradation patterns. Per-scenario staggering in parallel-execution model obscures these signals.

4. **Table/Operation Distribution** - Realistic spread across business operations prevents artificial hotspots where all VUs compete for the same resource. Reflects actual user behavior variance.

**Implementation:** Build composite launcher where each VU:

- Authenticates once per session
- Randomly selects operations from weighted distribution
- Maintains session for ~N API calls before cycling
- Runs under single configurable global VU cap

**Configuration Parameters to Define Before Run:**

- Target concurrent user count (e.g., 240, 180 for 75%, 120 for 50%)
- Ramp strategy (constant-vus, ramping-vus with stages)
- Operation weights (% CRUD, % read-heavy, % write-heavy, % targeted-stress)
- Session duration (number of API calls per user before re-auth)

## Execution Model: Deterministic Ramping + Weighted Random Operations

The composite launcher combines two independent sources of variation for **controlled randomization**:

### 1. VU Concurrency (Deterministic, Repeatable)

Each run uses an identical, predictable VU ramp for A-B testing consistency:

```
Stage 1: 0 VUs → 120 VUs over 5 minutes (50% backend capacity)
Stage 2: 120 VUs → 240 VUs over 10 minutes (100% backend capacity)
Stage 3: 240 VUs → 0 VUs over 5 minutes (graceful drain)
```

- Same ramp across all test runs ensures **repeatable baseline**
- A-B testing becomes possible: compare Server Config A vs B at identical concurrency curve
- New VUs authenticate naturally during ramp, eliminating need for staggering

### 2. Operation Dispatch (Random, Realistic)

Within each VU iteration, operations are selected via weighted random dispatch:

```
90% → CRUD operations (Customer, Warehouse, Department, etc.)  [CRUD_WEIGHT default: 0.9]
10% → NOOP (no-op) APIs (FloatAddition, StringShortFindIn, etc.)  [NOOP_WEIGHT default: 0.1]
 0% → Anomaly operations (simulate, leak, disrupt, files)  [all ANOMALY_*_WEIGHT default: 0.0]
```

- Each VU follows unpredictable operation sequence (realistic user behavior)
- Mix ensures non-uniform table access (no artificial single-table saturation)
- Weights tunable via environment variables

### 3. Finite Record Sets (Contention Control)

Setup phase creates bounded record pools per CRUD table:

```
e.g., 10 Customer records, 20 Inventory items, 50 Orders
```

VU concurrency + finite records = controllable contention ratio:

- Fewer records = higher contention (stress)
- More records = lower contention (realistic)
- Independent of VU count; tunable per config

### Controlled Randomization in Practice
```bash
# Baseline A-B test: same launcher, different config files
k6 run --env CONFIG_FILE=configs/load-baseline.json scripts/launchUnifiedScenario.js

# Stress variant: higher concurrency/duration via config
k6 run --env CONFIG_FILE=configs/stress-capacity.json scripts/launchUnifiedScenario.js

# Chaos variant: randomized stages from config
k6 run --env CONFIG_FILE=configs/chaos-60m.json scripts/launchUnifiedScenario.js
```

**Benefit:** Same deterministic concurrency curve enables server comparison; random operation sequence prevents test artifacts; both are tunable for scenario variation.

## Atomic Iteration Decision and Load Scaling

### Why Keep Iterations Atomic (1 action : 1 iteration)

For unified-scenario testing, each VU iteration should execute exactly one selected operation. This preserves sharp threshold signals:

- `http_req_failed` immediately reflects response failures from that action
- `http_req_duration` reflects request latency without blending unrelated journey steps
- Outliers are easier to attribute to a specific endpoint/path

If one iteration executes many actions (journey-style), delay/failure attribution becomes ambiguous unless additional per-step instrumentation is added.

### Tradeoff: Wider API Surface Requires Higher Total Work

Because unified launcher iterations are atomic while the operation pool is broad (many endpoints), defaults that are appropriate for single-script validation can under-sample endpoint coverage.

Implication:
- Keep atomic iterations for observability
- Increase overall load volume (VU count, total iterations, or stage targets/duration) to achieve sufficient endpoint exposure

### Practical Tuning Guidance (Unified Launcher)

1. Start from profile defaults to validate stability.
2. Scale load for coverage:
   - `load`: increase shared iterations and/or VUs
   - `stress`/`chaos`: raise stage targets and/or duration
3. Keep threshold intent explicit:
   - Request-level health: continue using `http_req_failed` and `http_req_duration`
   - Journey-level health (if later needed): add custom transaction metrics instead of overloading request-level thresholds

### Working Interpretation for Current Design

The current unified launcher behavior is correct by design:
- One operation is selected per VU iteration (`runUserFlow`)
- CRUD operations may issue multiple HTTP calls internally (e.g., PUT then GET) as one logical action
- To stress the full API surface while preserving sharp signals, increase total generated work rather than chaining many unrelated actions inside one iteration

## Sizing Rule For Multi-Scenario Runs

per_scenario_vus ~= backend_target_concurrency / scenario_count

Example:
- backend target: 240
- scenarios: 45
- recommended start: 4 to 5 VUs per scenario

## Run Guardrails

- Define before run: scenario count, per-scenario cap, theoretical max VUs, backend ceiling, oversubscription ratio.
- Track after run: reserve timeout count, no-available-connections count, auth error count, p95/p99 latency.

## Working RCA Assumption

Primary issue was throughput and capacity mismatch between generated parallel load and available ABL connection resources. Secondary issue was auth-layer error mapping that obscured capacity failures as credential-style failures.
