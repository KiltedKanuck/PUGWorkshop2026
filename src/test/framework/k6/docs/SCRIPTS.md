# Scripts and Execution Behavior

## Launcher Types: Multi-Scenario vs. Unified

This suite provides two launcher architectures. Understanding their differences is essential for choosing the right tool and predicting concurrency behavior.

### Multi-Scenario Launchers (launchEmployeeHR, launchCustomerSales, launchInventorySupplyChain, launchSystemConfig, launchObjects, launchProcedures, launchMultiScenario)

All launchers except `scripts/launchAuthOnly.js` and `scripts/launchUnifiedScenario.js` are **multi-scenario launchers**. Each declares multiple `options.scenarios` entries, where **k6 allocates a separate, independent VU pool per scenario**.

**Critical behavior: VU pool multiplication**

The total concurrent VUs running at any moment is the *sum* across all active scenario pools, not a shared cap:

```
Total potential VUs = scenario_count × MAX_VUS
```

For example, `scripts/launchMultiScenario.js` with 45 scenarios and `MAX_VUS=20` can generate up to 900 concurrent VUs. Even when individual scenario caps look reasonable, the aggregate can far exceed backend capacity. The default `MAX_VUS=20` was chosen to limit per-scenario overhead, but does **not** constrain the combined load.

**When to use:** Isolating a specific category of tests (Employee & HR, Inventory, Objects, etc.) where you want each resource exercised in its own dedicated execution lane.

**How staggering works:**

Each scenario receives a `startTime` offset based on its position in the launcher:
```
startTime = scenarioIndex × SCENARIO_STAGGER_SECONDS
```
With the default 0.5-second stagger, scenario 0 starts at `0s`, scenario 1 at `0.5s`, scenario 44 at `22s`. Auth load is spread across ~22 seconds instead of hitting all at once.

**Session continuity note:** Session continuity is reliable within one VU's lifecycle for a single scenario, but is not guaranteed across different scenario entries since k6 schedules them independently.

---

### Unified Scenario Launcher (launchUnifiedScenario)

`scripts/launchUnifiedScenario.js` uses a **single VU pool** shared across all 45 CRUD and NOOP operations. Rather than running scenarios in parallel, each VU randomly selects one operation per iteration from the combined pool, mimicking a real user who performs varied tasks within one authenticated session.

**Key difference from multi-scenario launchers:**

| Aspect | Multi-Scenario | Unified |
|--------|---------------|--------|
| VU pools | One per scenario (45 pools) | One global pool |
| Total VUs | `scenario_count × MAX_VUS` (uncontrolled sum) | Exactly what the profile specifies |
| Operation per iteration | Fixed to one scenario's test function | Random from all 45 operations |
| A-B testing | Difficult (aggregate concurrency varies) | Reliable (same VU count every run) |
| Auth | Per-VU, per-scenario | Per-VU, single session reused across operations |
| Staggering | Required to spread auth spike | Not needed; ramp handles distribution naturally |

**VU counts by profile for `scripts/launchUnifiedScenario.js`:**

The default profile in `scripts/launchUnifiedScenario.js` is `load`. Set `run.profile` in your config file to choose a profile.

**To target a known concurrency level** (e.g., 240 concurrent users matching server capacity), create a custom config file that extends `configs/profiles/stress.json` or `configs/profiles/chaos.json` and set the desired `env` values there.

**Key config fields for `scripts/launchUnifiedScenario.js`:**

| Variable | Default | Effect |
|----------|---------|--------|
| `run.profile` | `load` | Controls VU count and ramp shape (see profile table) |
| `env.DURATION` | `60` | Minutes of chaos stages when using `chaos` profile |
| `env.MAX_VUS` | `20` | Upper bound for random VU targets in chaos stages |

**Usage examples:**

```bat
k6 run --env CONFIG_FILE=configs/load-baseline.json scripts/launchUnifiedScenario.js
k6 run --env CONFIG_FILE=configs/stress-capacity.json scripts/launchUnifiedScenario.js
k6 run --env CONFIG_FILE=configs/chaos-60m.json scripts/launchUnifiedScenario.js

rem A-B test: run twice against different server configs; same VU concurrency each time
k6 run --env CONFIG_FILE=configs/load-host-a.json scripts/launchUnifiedScenario.js
k6 run --env CONFIG_FILE=configs/load-host-b.json scripts/launchUnifiedScenario.js
```

### Per-User Authentication (all launchers)

All launchers perform login in the Virtual User execution context (not in `setup()`):

- authentication is enabled by default and can be disabled with `env.AUTH_REQUIRED=false` in config
- each Virtual User logs in with username `<AUTH_USERNAME_PREFIX>-<VU_ID>`
- with `AUTH_STICKY_SESSIONS=true` (default), top-level launcher options set `noCookiesReset: true`, so a VU can keep reusing the same authenticated session across iterations
- with `AUTH_STICKY_SESSIONS=false`, k6 resets cookies between iterations, so later iterations may re-authenticate that same username
- optional per-iteration logout is controlled by `AUTH_LOGOUT_EACH_ITERATION`

When running any launcher or single script directly from `scripts/...`, usernames follow the same pattern, for example: `<AUTH_USERNAME_PREFIX>-1`.

Example:

```bat
k6 run --env CONFIG_FILE=configs/chaos-60m.json scripts/launchMultiScenario.js
k6 run --env CONFIG_FILE=configs/auth-required-false.json scripts/launchMultiScenario.js
k6 run --env CONFIG_FILE=configs/auth-sticky.json scripts/launchMultiScenario.js
k6 run --env CONFIG_FILE=configs/auth-logout-smoke.json scripts/launchMultiScenario.js
```

### Authentication Only

Use `scripts/launchAuthOnly.js` to test only PASOE/Tomcat login behavior, without the record setup and API traffic from the other launchers:

- Execution order is: login -> validate OpenAPI session -> optional logout (`AUTH_LOGOUT_EACH_ITERATION=true`)
- Validates authenticated sessions by making an OpenAPI call after login
- Exits as soon as the login-only scenario completes, so it is the fastest way to confirm whether Virtual Users are actually establishing authenticated sessions

Examples:

```bat
k6 run --env CONFIG_FILE=configs/smoke-local.json scripts/launchAuthOnly.js
k6 run --env CONFIG_FILE=configs/auth-known-user-load.json scripts/launchAuthOnly.js
k6 run --env CONFIG_FILE=configs/auth-logout-smoke.json scripts/launchAuthOnly.js
k6 run --env CONFIG_FILE=configs/auth-debug-smoke.json scripts/launchAuthOnly.js
```

`scripts/launchAuthOnly.js` requires `AUTH_REQUIRED=true` and will fail fast if authentication is disabled.

To capture authentication event logs to a file using `AUTH_DEBUG=true` and `--console-output`, see [OUTPUT.md](OUTPUT.md).

The full output will show login status, session validation via OpenAPI, and any authentication errors encountered.

### Profiles

As noted, profiles represent a consistent form of test that should be executed for OELS testing. Set `run.profile` in your config file to control test intensity and scenario shape:

| Profile  | Executor  | Description                                        |
|----------|-----------|----------------------------------------------------|
| `simple` | shared-iterations | Single-pass flow (default when PROFILE is omitted) |
| `smoke`  | shared-iterations | 1 Virtual User, 1 total shared iteration - quick sanity check |
| `load`   | shared-iterations | 5 VUs executing 20 total shared iterations (not 20 each) |
| `stress` | ramping-vus | Stair-stepped ramp-up / ramp-down stages, high concurrency |
| `chaos`  | ramping-vus | Random Virtual User load via random stages for specified duration |
---

## Test Execution Model

CRUD tests follow a deterministic, single-transaction-per-iteration execution model:

### Execution Paths by Profile

**Smoke & Simple profiles** (always 1 seeded record):
- Execute a single **deterministic sequence: GET → PUT → GET**
- Gets a record, updates it, re-fetches to validate
- Think time applied between each operation (0.1–2.0 seconds)
- Scenario stagger: all scenarios start immediately (0s offset) for simple profile

**Load, Stress & Chaos profiles** (`SEED_RECORD_RATIO=1` default, pool = `round(MAX_VUS / ratio)`):
- Execute a single **PUT → GET cycle** on a randomly-selected record from the pool
- Each iteration picks a random record ID and updates it, then verifies the update
- Default ratio of 1 seeds exactly `MAX_VUS` records, giving each VU its own dedicated record
- Think time applied between PUT and GET (0.1–2.0 seconds)
- Scenario stagger: 0.5 seconds between each scenario start (spreads auth load)

### Iteration Duration Composition

For non-smoke profiles, each iteration time consists of:

```
Iteration Duration = PUT_time + think_time + GET_time
```

Where:
- `PUT_time` - time to execute the update operation
- `think_time` - random sleep between MIN_THINK_TIME and MAX_THINK_TIME (simulates user delay)
- `GET_time` - time to verify the updated record

Total VU throughput is calculated as: `VUs × (iterations / total_duration)`

---

## Metrics Interpretation

The execution model produces metrics that accurately reflect test behavior:

### Key Metrics

| Metric | Meaning |
|--------|----------|
| `iteration_duration` | Time for one PUT→GET cycle (includes think time). Reflects the complete business transaction time per iteration. |
| `http_req_duration` | HTTP round-trip time for individual PUT or GET request (excludes think time). |
| `http_req_waiting` | Server processing time (time-to-first-byte). Includes database lock contention and server processing. |
| `data_received` | Total response bytes across all requests in the iteration. |
| `data_sent` | Total request bytes across all requests in the iteration. |

### Think Time Impact

Think time is included in `iteration_duration`, so high think time values increase the apparent duration per iteration. This is intentional - it models realistic user behavior where users take time between actions.

For example:
- `iteration_duration` = 2500ms is realistic (50ms PUT + 1900ms think + 50ms GET)
- Without think time, the same scenario would show `iteration_duration` ≈ 100ms

### Cross-Scenario Comparisons

Metrics are comparable across all CRUD scripts because they all follow the same execution pattern:
- Each iteration = one record mutation
- Each scenario = one deterministic PUT→GET cycle
- Think time is consistently applied across all scripts

---

## Replicating Record Conflicts

Record conflicts can be reproduced by adjusting the ratio of Virtual Users to the record pool size.

### Understanding Lock Conflicts

Lock conflicts occur when multiple VUs attempt to update the same record simultaneously:
- VU1 reads record X
- VU2 reads record X simultaneously
- VU1 updates record X (lock acquired)
- VU2 tries to update record X (lock wait/timeout → failure)

### Scaling Strategy for Conflicts

The conflict rate depends on the VU-to-record ratio, controlled by `SEED_RECORD_RATIO`.
The record pool is computed as `round(MAX_VUS / SEED_RECORD_RATIO)`, so the pool scales automatically when `MAX_VUS` changes.

| Scenario | `MAX_VUS` | `SEED_RECORD_RATIO` | Records | VU:Record | Conflict Likelihood |
|----------|-----------|---------------------|---------|-----------|---------------------|
| Baseline (default) | 20 | 1 | 20 | 1:1 | Very low (~0.5%) |
| Light contention | 20 | 2 | 10 | 2:1 | Low (~5%) |
| Medium contention | 20 | 3 | 7 | 3:1 | Medium (~15%) |
| High contention | 20 | 4 | 5 | 4:1 | High (~30%) |
| Maximum contention | 20 | 20 | 1 | 20:1 | Very high (~70%+) |

### Reproducing Different Conflict Levels

**Example 1: Light contention test**
```bat
k6 run --env CONFIG_FILE=configs/contention-light.json scripts/launchMultiScenario.js
```
This runs 50 VUs per scenario against 25 records (50 / 2) for 2 minutes, creating light contention (~5% failure rate expected).

**Example 2: Medium contention test**
```bat
k6 run --env CONFIG_FILE=configs/contention-medium-stress.json scripts/launchCustomerSales.js
```
Stress profile ramps to high VU count with a 3:1 VU-to-record ratio, creating 15–25% lock contention.

**Example 3: Maximum contention benchmark**
```bat
k6 run --env CONFIG_FILE=configs/contention-max.json scripts/launchMultiScenario.js
```
Forces 100 VUs per scenario to compete for only 5 records (100 / 20), maximizing lock conflicts for worst-case testing.

### Interpreting Lock Conflict Results

When running a conflict-heavy test, expect:
- Higher `http_req_waiting` times (server spends time waiting for locks)
- Increased `http_req_duration` variability
- Check failures tagged with "lock" or "timeout" in the failure diagnostics
- Overall test duration may be longer as VUs wait for locks

If failures exceed expected thresholds:
1. Review server-side lock configurations (deadlock detection, timeout values)
2. Decrease `SEED_RECORD_RATIO` to reduce contention (more records per VU)
3. Increase `MAX_THINK_TIME` to reduce simultaneous access windows
4. Consider implementing record-locking strategies in application code

---

### Group 1 - Employee & HR (6 tests)

Tests: department, employee, benefits, family, timesheet, vacation

```bat
k6 run --env CONFIG_FILE=configs/smoke-local.json scripts/launchEmployeeHR.js
k6 run --env CONFIG_FILE=configs/load-baseline.json scripts/launchEmployeeHR.js
k6 run --env CONFIG_FILE=configs/stress-capacity.json scripts/launchEmployeeHR.js
k6 run --env CONFIG_FILE=configs/chaos-60m.json scripts/launchEmployeeHR.js
```

---

### Group 2 - Customer & Sales (9 tests)

Tests: customer, billto, shipto, salesrep, order, orderline, invoice, feedback, refcall

```bat
k6 run --env CONFIG_FILE=configs/smoke-local.json scripts/launchCustomerSales.js
k6 run --env CONFIG_FILE=configs/load-baseline.json scripts/launchCustomerSales.js
k6 run --env CONFIG_FILE=configs/stress-capacity.json scripts/launchCustomerSales.js
k6 run --env CONFIG_FILE=configs/chaos-60m.json scripts/launchCustomerSales.js
```

---

### Group 3 - Inventory & Supply Chain (8 tests)

Tests: item, bin, warehouse, inventorytrans, supplier, supplieritemxref, purchaseorder, poline

```bat
k6 run --env CONFIG_FILE=configs/smoke-local.json scripts/launchInventorySupplyChain.js
k6 run --env CONFIG_FILE=configs/load-baseline.json scripts/launchInventorySupplyChain.js
k6 run --env CONFIG_FILE=configs/stress-capacity.json scripts/launchInventorySupplyChain.js
k6 run --env CONFIG_FILE=configs/chaos-60m.json scripts/launchInventorySupplyChain.js
```

---

### Group 4 - System & Configuration (2 tests)

Tests: state, localdefault

```bat
k6 run --env CONFIG_FILE=configs/smoke-local.json scripts/launchSystemConfig.js
k6 run --env CONFIG_FILE=configs/load-baseline.json scripts/launchSystemConfig.js
k6 run --env CONFIG_FILE=configs/stress-capacity.json scripts/launchSystemConfig.js
k6 run --env CONFIG_FILE=configs/chaos-60m.json scripts/launchSystemConfig.js
```

---

### Objects Service (20 launcher scenarios)

Stateless math, string, and temp-table tests for `/objects/*` endpoints.
Two endpoints (`temptableaddrecords`, `temptabledeletatable`) are excluded from `scripts/launchObjects.js` due to server-side stateless-session bug ABL error 3135.

```bat
k6 run --env CONFIG_FILE=configs/smoke-local.json scripts/launchObjects.js
k6 run --env CONFIG_FILE=configs/load-baseline.json scripts/launchObjects.js
k6 run --env CONFIG_FILE=configs/stress-capacity.json scripts/launchObjects.js
k6 run --env CONFIG_FILE=configs/chaos-60m.json scripts/launchObjects.js
```

---

### Procedures Service (20 launcher scenarios)

Procedures launcher scenarios are available for `/procedures/*` endpoints.
Two endpoints (`temptableaddrecords`, `temptabledeletatable`) are excluded from `scripts/launchProcedures.js` due to ABL error 3135.

```bat
k6 run --env CONFIG_FILE=configs/smoke-local.json scripts/launchProcedures.js
k6 run --env CONFIG_FILE=configs/load-baseline.json scripts/launchProcedures.js
k6 run --env CONFIG_FILE=configs/stress-capacity.json scripts/launchProcedures.js
k6 run --env CONFIG_FILE=configs/chaos-60m.json scripts/launchProcedures.js
```

---

### Multi-Scenario Full Suite (launchMultiScenario)

Runs all available test scenarios simultaneously in one multi-scenario launcher:
- CRUD groups: Employee and HR, Customer and Sales, Inventory and Supply Chain, System and Configuration
- Objects service tests

Each of the 45 scenarios runs in its own independent VU pool. Total potential concurrency = `45 × MAX_VUS`. Use this launcher when you want every resource exercised in parallel under independent load shapes.

Excludes:
- Procedures service tests (server-blocked: HTTP 500 / ABL error 5425)
- `temptableaddrecords` and `temptabledeletatable` (server-side ABL error 3135)

```bat
k6 run --env CONFIG_FILE=configs/chaos-60m.json scripts/launchMultiScenario.js
k6 run --env CONFIG_FILE=configs/multi-5vus-chaos-60m.json scripts/launchMultiScenario.js
```

> **Capacity note:** With 45 scenarios and the default `MAX_VUS=20`, up to 900 VUs may be active simultaneously. Set `env.MAX_VUS` to `backend_connection_limit / scenario_count` (e.g., `240 / 45 ≈ 5`) to avoid backend oversubscription. See `MULTI_SCENARIO.md` for the full analysis.

### Unified Full Suite (launchUnifiedScenario)

Runs all CRUD and NOOP operations through a **single VU pool** with randomly dispatched operations per iteration. This is the recommended launcher for A-B testing and capacity-aligned load measurement.

See the [Unified Scenario Launcher](#unified-scenario-launcher-launchunifiedscenario) section above for full details and VU defaults by profile.

```bat
k6 run --env CONFIG_FILE=configs/load-baseline.json scripts/launchUnifiedScenario.js
k6 run --env CONFIG_FILE=configs/stress-capacity.json scripts/launchUnifiedScenario.js
k6 run --env CONFIG_FILE=configs/chaos-60m.json scripts/launchUnifiedScenario.js
```

---

## Running a Single Test

Run individual scripts directly from the k6 folder. For consistency with the config-first launcher flow, prefer wrapper launchers and config files for most runs.

```bat
k6 run scripts/crud/state.js
k6 run scripts/objects/floataddition.js
```

Single-script auth behavior matches the launchers:

- default: cookies reset between iterations, so the same VU username may log in again on later iterations
- sticky: `AUTH_STICKY_SESSIONS=true` keeps the VU session across iterations for profile-based runs

Set `env.BASE_URL` in the config file when running via launcher wrappers.

### Tunable Parameters (CRUD tests)

| Variable   | Default | Description |
|------------|---------|-------------|
| `BASE_URL` | `http://127.0.0.1:7780` | API host |
| `PROFILE`  | `smoke` | Test profile (simple/smoke/load/stress/chaos) |

---

## CRUD Test Files

| File | Endpoint | Group |
|------|----------|-------|
| `scripts/crud/benefits.js` | /data/benefits | Employee and HR |
| `scripts/crud/billto.js` | /data/billto | Customer and Sales |
| `scripts/crud/bin.js` | /data/bin | Inventory and Supply Chain |
| `scripts/crud/customer.js` | /data/customer | Customer and Sales |
| `scripts/crud/department.js` | /data/department | Employee and HR |
| `scripts/crud/employee.js` | /data/employee | Employee and HR |
| `scripts/crud/family.js` | /data/family | Employee and HR |
| `scripts/crud/feedback.js` | /data/feedback | Customer and Sales |
| `scripts/crud/inventorytrans.js` | /data/inventorytrans | Inventory and Supply Chain |
| `scripts/crud/invoice.js` | /data/invoice | Customer and Sales |
| `scripts/crud/item.js` | /data/item | Inventory and Supply Chain |
| `scripts/crud/localdefault.js` | /data/localdefault | System and Configuration |
| `scripts/crud/order.js` | /data/order | Customer and Sales |
| `scripts/crud/orderline.js` | /data/orderline | Customer and Sales |
| `scripts/crud/poline.js` | /data/poline | Inventory and Supply Chain |
| `scripts/crud/purchaseorder.js` | /data/purchaseorder | Inventory and Supply Chain |
| `scripts/crud/refcall.js` | /data/refcall | Customer and Sales |
| `scripts/crud/salesrep.js` | /data/salesrep | Customer and Sales |
| `scripts/crud/shipto.js` | /data/shipto | Customer and Sales |
| `scripts/crud/state.js` | /data/state | System and Configuration |
| `scripts/crud/supplier.js` | /data/supplier | Inventory and Supply Chain |
| `scripts/crud/supplieritemxref.js` | /data/supplieritemxref | Inventory and Supply Chain |
| `scripts/crud/timesheet.js` | /data/timesheet | Employee and HR |
| `scripts/crud/vacation.js` | /data/vacation | Employee and HR |
| `scripts/crud/warehouse.js` | /data/warehouse | Inventory and Supply Chain |

---

## Objects Test Files

> Two objects endpoints are also excluded from `scripts/launchObjects.js` due to ABL error 3135:
> `scripts/objects/temptableaddrecords.js` and `scripts/objects/temptabledeletatable.js`.

| File | Endpoint |
|------|----------|
| `scripts/objects/floataddition.js` | /objects/float/addition |
| `scripts/objects/floatdivision.js` | /objects/float/division |
| `scripts/objects/floatmultiplication.js` | /objects/float/multiplication |
| `scripts/objects/floatsubtraction.js` | /objects/float/subtraction |
| `scripts/objects/integeraddition.js` | /objects/integer/addition |
| `scripts/objects/integerdivision.js` | /objects/integer/division |
| `scripts/objects/integermultiplication.js` | /objects/integer/multiplication |
| `scripts/objects/integersubtraction.js` | /objects/integer/subtraction |
| `scripts/objects/longaddition.js` | /objects/long/addition |
| `scripts/objects/longdivision.js` | /objects/long/division |
| `scripts/objects/longmultiplication.js` | /objects/long/multiplication |
| `scripts/objects/longsubtraction.js` | /objects/long/subtraction |
| `scripts/objects/stringlongwhatletter.js` | /objects/string/long/whatletter |
| `scripts/objects/stringlongwhatword.js` | /objects/string/long/whatword |
| `scripts/objects/stringshortfindin.js` | /objects/string/short/findin |
| `scripts/objects/stringshorthellojoin.js` | /objects/string/short/hellojoin |
| `scripts/objects/stringshortwhatletter.js` | /objects/string/short/whatletter |
| `scripts/objects/stringshortWhatword.js` | /objects/string/short/whatword |
| `scripts/objects/temptableaddrecords.js` | /objects/temptable/addRecords |
| `scripts/objects/temptablecreatedynamic.js` | /objects/temptable/createDynamic |
| `scripts/objects/temptablecreatestatic.js` | /objects/temptable/createStatic |
| `scripts/objects/temptabledeletatable.js` | /objects/temptable/deleteTable |

---

## Procedures Test Files

> Two procedures endpoints are also excluded from `scripts/launchProcedures.js` due to ABL error 3135:
> `scripts/procedures/temptableaddrecords.js` and `scripts/procedures/temptabledeletatable.js`.

| File | Endpoint |
|------|----------|
| `scripts/procedures/floataddition.js` | /procedures/float/addition |
| `scripts/procedures/floatdivision.js` | /procedures/float/division |
| `scripts/procedures/floatmultiplication.js` | /procedures/float/multiplication |
| `scripts/procedures/floatsubtraction.js` | /procedures/float/subtraction |
| `scripts/procedures/integeraddition.js` | /procedures/integer/addition |
| `scripts/procedures/integerdivision.js` | /procedures/integer/division |
| `scripts/procedures/integermultiplication.js` | /procedures/integer/multiplication |
| `scripts/procedures/integersubtraction.js` | /procedures/integer/subtraction |
| `scripts/procedures/longaddition.js` | /procedures/long/addition |
| `scripts/procedures/longdivision.js` | /procedures/long/division |
| `scripts/procedures/longmultiplication.js` | /procedures/long/multiplication |
| `scripts/procedures/longsubtraction.js` | /procedures/long/subtraction |
| `scripts/procedures/stringlongwhatletter.js` | /procedures/string/long/whatletter |
| `scripts/procedures/stringlongwhatword.js` | /procedures/string/long/whatword |
| `scripts/procedures/stringshortfindin.js` | /procedures/string/short/findin |
| `scripts/procedures/stringshorthellojoin.js` | /procedures/string/short/hellojoin |
| `scripts/procedures/stringshortwhatletter.js` | /procedures/string/short/whatletter |
| `scripts/procedures/stringshortWhatword.js` | /procedures/string/short/whatword |
| `scripts/procedures/temptableaddrecords.js` | /procedures/temptable/addRecords |
| `scripts/procedures/temptablecreatedynamic.js` | /procedures/temptable/createDynamic |
| `scripts/procedures/temptablecreatestatic.js` | /procedures/temptable/createStatic |
| `scripts/procedures/temptabledeletatable.js` | /procedures/temptable/deleteTable |

---

## Failure Diagnostics

The test framework includes a structured failure capture layer that is available across all script types (CRUD, auth, objects, and procedures). It is **off by default** and adds no overhead to normal runs.

### Output destinations

k6 writes to two distinct output channels and the diagnostics layer uses both:

| Output | Where it goes | Captured by |
|---|---|---|
| End-of-run summary (metrics, thresholds, counters) | **stdout** - always printed to the terminal | `--summary-export=<file>` writes it as JSON; otherwise read from terminal output |
| `console.error` / `console.log` lines (per-failure JSON events, auth debug lines) | **stderr** - printed to the terminal interleaved with the progress output | `--console-output=<file>` redirects **all** console output to a file instead of stderr |

Key points:
- The `debug_failure_events` counter is a standard k6 metric - it appears in the **summary on stdout** and is always captured by `--summary-export` without needing `--console-output`.
- Per-failure JSON event lines use `console.error` and go to **stderr**. Without `--console-output` they appear in the terminal but are not written to any file automatically.
- `--console-output` redirects the entire console output stream (both `console.log` and `console.error`) to the specified file. When set, those lines no longer appear in the terminal.
- Shell-level stderr redirection (`2>file`) also works if you need to keep console output in the terminal and separately capture it.

### How it works

Every check failure calls `captureFailureContext()` in `common/diagnostics.js`, which:

1. **Always** increments the `debug_failure_events` custom k6 counter, tagged by `failure_type` and `scenario`. This counter appears in the end-of-run **summary (stdout)** and in `--summary-export` output - no additional flags needed.
2. **Only when `ENABLE_FAILURE_DIAGNOSTICS=true`** emits one `console.error` line per failure as a compact JSON event to **stderr**. Capture this with `--console-output` or shell stderr redirection.

Each JSON event contains:

| Field | Description |
|-------|-------------|
| `ts` | ISO timestamp of the failure |
| `failureType` | Category: `auth_login_failure`, `auth_logout_failure`, `auth_session_validation_failure`, `crud_check_failure`, `service_result_failure` |
| `failedChecks` | Array of check names that did not pass |
| `scenario` | k6 scenario name |
| `vu` | Virtual User ID |
| `iteration` | Iteration number within the scenario |
| `method` | HTTP method (GET, POST, PUT, DELETE) |
| `url` | Full request URL |
| `status` | HTTP response status code |
| `error` | k6 network error string, if present |
| `errorCode` | k6 numeric error code, if present |
| `timings` | Full k6 request timing breakdown |
| `bodySnippet` | Truncated response body (bounded by `FAILURE_BODY_SNIPPET_LENGTH`) |
| `metadata` | Context specific to the failure source (resource name, phase, PK, expected result, predicate exceptions) |

### Coverage

| Script type | Failure types captured |
|---|---|
| CRUD (`scripts/crud/*.js`) | `crud_check_failure` - status, contract, server error checks |
| Auth (`common/auth.js`) | `auth_login_failure`, `auth_logout_failure`, `auth_session_validation_failure` |
| Objects (`scripts/objects/*.js`) | `service_result_failure` - all result checks via `validateServiceResults()` |
| Procedures (`scripts/procedures/*.js`) | `service_result_failure` - all result checks via `validateServiceResults()` |

### Environment variables

| Variable | Default | Description |
|---|---|---|
| `ENABLE_FAILURE_DIAGNOSTICS` | `true` | Emit per-failure JSON log lines to stderr. Set `false` to disable diagnostics output. |
| `FAILURE_LOG_LIMIT_PER_VU` | `0` | Maximum failure log lines emitted per VU. Set to `0` to remove the cap entirely and log every failure. The `debug_failure_events` counter is **never** capped regardless of this value. |
| `FAILURE_BODY_SNIPPET_LENGTH` | `1024` | Maximum characters of the response body captured per event. Minimum enforced value is `80`. |

### What can and cannot limit diagnostic output

**Nothing in the diagnostic layer stops or aborts a test.** `captureFailureContext()` never calls `fail()` or aborts an iteration - it only records and logs. Any `fail()` calls that exist in `crud.js` and `auth.js` were already there before diagnostics were added; they run after `captureFailureContext()` returns.

The only two limits that affect what gets logged are:

1. **`FAILURE_LOG_LIMIT_PER_VU`** - caps the number of `console.error` JSON lines emitted per VU per run. This only affects the verbose per-failure log lines. It does **not** affect the `debug_failure_events` counter, which always increments for every failure unconditionally. Set to `0` to remove the cap entirely.

2. **`FAILURE_BODY_SNIPPET_LENGTH`** - truncates the response body field in each JSON event to avoid very large log lines. The event is still emitted; only the body field is cut. The minimum enforced value is `80` characters so the field is never completely empty.

The `debug_failure_events` counter is always accurate regardless of both limits above - it is the reliable source for total failure counts even when log lines are suppressed.

### Recommended debug run

`scripts/launchMultiScenario.js` builds its scenarios directly via `makeChaosScenario()`, so treat it as chaos-oriented and tune behavior through config values.

For other launchers (`scripts/launchEmployeeHR.js`, `scripts/launchObjects.js`, `scripts/launchUnifiedScenario.js`, etc.), set profile and env tuning through the selected config file.

To diagnose failures in the multi-scenario launcher with full diagnostics enabled:

```bat
k6 run ^
  --env CONFIG_FILE=configs/diagnostics-chaos.json ^
  --console-output=failures.log ^
  --summary-export=summary.json ^
  scripts/launchMultiScenario.js
```

What each flag produces:

- `--summary-export` - writes the end-of-run summary (including `debug_failure_events` counts) as JSON to the specified file. The summary is **also** still printed to stdout in the terminal.
- `--console-output` - redirects all `console.error` / `console.log` output (the per-failure JSON events) to the specified file. Those lines will **not** appear in the terminal when this flag is set.

To see failure events in the terminal **and** capture them to a file, omit `--console-output` and use shell redirection instead:

```bat
k6 run ^
  --env CONFIG_FILE=configs/diagnostics-chaos.json ^
  --summary-export=summary.json ^
  scripts/launchMultiScenario.js 2>failures.log
```

Running without diagnostics enabled in config still produces the `debug_failure_events` counter in the summary - useful when you want failure counts by type and scenario without the per-failure detail.
