# k6 Scenario and Option Reference

This document is generated from the k6 JavaScript sources under `src/test/framework/k6`.
It summarizes:

- all scenario types/profiles
- all launcher scenario names
- all supported `--env` options that the scripts read

## 1) Profile Scenarios (`PROFILE`)

All standalone test scripts (`scripts/crud/*`, `scripts/objects/*`, `scripts/procedures/*`) use:

```js
export const options = buildScenarioFromProfile();
```

So they all support these profile scenarios:

| Profile | Scenario shape | Primary k6 options set | Default thresholds/tags |
|---|---|---|---|
| `simple` (default fallback) | single-pass sanity | `iterations: 1`, `vus: 1`, `noCookiesReset` | `http_req_failed: rate==0`, `http_req_duration: p(95)<1500`, `tags.profile=simple` |
| `smoke` | quick validation | `iterations: 1`, `vus: 1`, `noCookiesReset` | `http_req_failed: rate==0`, `http_req_duration: p(95)<2000`, `checks: rate==1`, `tags.profile=smoke` |
| `load` | steady shared iterations | `iterations: MAX_ITERATIONS`, `vus: MAX_VUS`, `noCookiesReset` | `http_req_failed: rate<0.02`, `http_req_duration: p(95)<9500`, `tags.profile=load` |
| `stress` | staged ramping | `stages: 5 steps` (to `MAX_VUS` then cooldown), `noCookiesReset` | `http_req_failed: rate<0.02`, `http_req_duration: p(95)<9500`, `tags.profile=stress` |
| `chaos` | random ramping | `stages: generateRandomStages(DURATION)`, `noCookiesReset` | no default thresholds in profile object |

Example request in your format:

- `smoke` - options: `iterations=1`, `vus=1`, `noCookiesReset=<AUTH_STICKY_SESSIONS>`, strict thresholds
- `load` - options: `iterations=<MAX_ITERATIONS>`, `vus=<MAX_VUS>`, `noCookiesReset=<AUTH_STICKY_SESSIONS>`
- `stress` - options: `stages=[...5 stages...]`, `noCookiesReset=<AUTH_STICKY_SESSIONS>`
- `chaos` - options: `stages=generateRandomStages(DURATION)`, `noCookiesReset=<AUTH_STICKY_SESSIONS>`

## 2) Launcher Scenarios

## `scripts/launchAuthOnly.js`

- Scenario model: single default function (no `options.scenarios` map)
- Base options: from `buildScenarioFromProfile()`
- Overrides:
  - `thresholds.http_req_duration = p(95)<10000`
  - `tags.launcher = launchAuthOnly`
- Launcher default profile: whatever `PROFILE` resolves to (global default is `simple`)

## `scripts/launchUnifiedScenario.js`

- Scenario model: single default function that randomly dispatches all operations
- Base options: from `buildScenarioFromProfile()`
- Adds:
  - `setupTimeout: 20m`
  - `teardownTimeout: 20m`
  - `tags.launcher = launchUnifiedScenario`
- Launcher default profile override: `load` when `PROFILE` not supplied

## `scripts/launchMultiScenario.js`

- Scenario model: explicit `options.scenarios` with independent chaos schedules
- Uses `makeChaosScenario(execName)` per scenario. Each scenario gets:
  - `executor: ramping-vus`
  - `exec: <exported function name>`
  - `startTime: <index * SCENARIO_STAGGER_SECONDS>s`
  - `startVUs: 0`
  - `stages: generateRandomStages(DURATION)`
  - `tags.profile = chaos`, `tags.name = <execName>`, `tags.params = "<DURATION> mins / <MAX_VUS> vus"`
  - `gracefulStop: 30s`
- Top-level launcher options:
  - `tags.launcher = launchMultiScenario`
  - `setupTimeout: 20m`
  - `teardownTimeout: 20m`
  - thresholds:
    - `checks{profile:chaos}: rate>=0.95`
    - `http_req_failed{profile:chaos}: rate<0.05`
- Launcher default profile override: `chaos` when `PROFILE` not supplied

Scenarios in `scripts/launchMultiScenario.js`:

- CRUD: `Department`, `Employee`, `Benefits`, `Family`, `Timesheet`, `Vacation`, `Customer`, `Billto`, `Shipto`, `Salesrep`, `Order`, `Orderline`, `Invoice`, `Feedback`, `Refcall`, `Item`, `Bin`, `Warehouse`, `Inventorytrans`, `Supplier`, `Supplieritemxref`, `Purchaseorder`, `Poline`, `State`, `Localdefault`
- Objects: `FloatAddition`, `FloatDivision`, `FloatMultiplication`, `FloatSubtraction`, `IntegerAddition`, `IntegerDivision`, `IntegerMultiplication`, `IntegerSubtraction`, `LongAddition`, `LongDivision`, `LongMultiplication`, `LongSubtraction`, `StringLongWhatLetter`, `StringLongWhatWord`, `StringShortFindIn`, `StringShortHelloJoin`, `StringShortWhatLetter`, `StringShortWhatWord`, `TemptableCreateDynamic`, `TemptableCreateStatic`

## `scripts/launchEmployeeHR.js`

- Scenario names: `Department`, `Employee`, `Benefits`, `Family`, `Timesheet`, `Vacation`
- Per-scenario options: from `buildLauncherScenarioFromProfile()`
- Top-level options: `noCookiesReset`, `tags.launcher=launchEmployeeHR`, thresholds `http_req_failed<0.05`, `checks>=0.95`

## `scripts/launchCustomerSales.js`

- Scenario names: `Customer`, `Billto`, `Shipto`, `Salesrep`, `Order`, `Orderline`, `Invoice`, `Feedback`, `Refcall`
- Per-scenario options: from `buildLauncherScenarioFromProfile()`
- Top-level options: `noCookiesReset`, `tags.launcher=launchCustomerSales`, thresholds `http_req_failed<0.05`, `checks>=0.95`

## `scripts/launchInventorySupplyChain.js`

- Scenario names: `Item`, `Bin`, `Warehouse`, `Inventorytrans`, `Supplier`, `Supplieritemxref`, `Purchaseorder`, `Poline`
- Per-scenario options: from `buildLauncherScenarioFromProfile()`
- Top-level options: `noCookiesReset`, `tags.launcher=launchInventorySupplyChain`, thresholds `http_req_failed<0.05`, `checks>=0.95`

## `scripts/launchSystemConfig.js`

- Scenario names: `State`, `Localdefault`
- Per-scenario options: from `buildLauncherScenarioFromProfile()`
- Top-level options: `noCookiesReset`, `tags.launcher=launchSystemConfig`, thresholds `http_req_failed<0.05`, `checks>=0.95`

## `scripts/launchObjects.js`

- Scenario names: `FloatAddition`, `FloatDivision`, `FloatMultiplication`, `FloatSubtraction`, `IntegerAddition`, `IntegerDivision`, `IntegerMultiplication`, `IntegerSubtraction`, `LongAddition`, `LongDivision`, `LongMultiplication`, `LongSubtraction`, `StringLongWhatLetter`, `StringLongWhatWord`, `StringShortFindIn`, `StringShortHelloJoin`, `StringShortWhatLetter`, `StringShortWhatWord`, `TemptableCreateDynamic`, `TemptableCreateStatic`
- Per-scenario options: from `buildLauncherScenarioFromProfile()`
- Top-level options: `noCookiesReset`, `tags.launcher=launchObjects`, thresholds `http_req_failed==0`, `checks==1`
- Excluded from launcher: `TemptableAddRecords`, `TemptableDeleteTable`

## `scripts/launchProcedures.js`

- Scenario names: `FloatAddition`, `FloatDivision`, `FloatMultiplication`, `FloatSubtraction`, `IntegerAddition`, `IntegerDivision`, `IntegerMultiplication`, `IntegerSubtraction`, `LongAddition`, `LongDivision`, `LongMultiplication`, `LongSubtraction`, `StringLongWhatLetter`, `StringLongWhatWord`, `StringShortFindIn`, `StringShortHelloJoin`, `StringShortWhatLetter`, `StringShortWhatWord`, `TemptableCreateDynamic`, `TemptableCreateStatic`
- Per-scenario options: from `buildLauncherScenarioFromProfile()`
- Top-level options: `noCookiesReset`, `tags.launcher=launchProcedures`, thresholds `http_req_failed==0`, `checks==1`
- Excluded from launcher: `TemptableAddRecords`, `TemptableDeleteTable`

## 3) `--env` Options Supported by the Scripts

These are all environment variables referenced in the k6 JS source.

| `--env` variable | Default | Used for |
|---|---|---|
| `PROFILE` | `simple` globally; launcher overrides in `launchUnifiedScenario` (`load`) and `launchMultiScenario` (`chaos`) | Selects scenario profile shape |
| `BASE_URL` | `http://127.0.0.1:7780` | Server host/port for all API calls |
| `MAX_VUS` | `20` (min 2) | Load/stress/chaos VU ceilings and stage targets |
| `MAX_ITERATIONS` | `100` (min 1) | Shared-iterations total for load-style profiles |
| `DURATION` | `10` (min 5) | Stress and chaos stage duration basis |
| `IDLE_STAGE_CHANCE` | `0.05` | Chance each chaos stage goes to 0 VUs |
| `SCENARIO_STAGGER_SECONDS` | `0.5` | Start delay increment between chaos scenarios |
| `MIN_THINK_TIME` | `0.1` | Iteration pause for load/stress and lower bound for chaos |
| `MAX_THINK_TIME` | `1.0` | Chaos-only upper bound for random think time |
| `SEED_RECORD_RATIO` | `1` | CRUD setup seed pool sizing ratio |
| `API_PATH` | per CRUD script default (`/devsuite/web/api/data/<resource>`) | Override CRUD endpoint path |
| `AUTH_REQUIRED` | `true` | Require per-VU login before requests |
| `AUTH_USERNAME_PREFIX` | `oels-vu` | Username format `<prefix>-<VU_ID>` |
| `AUTH_PASSWORD` | `password` | Password for auth login |
| `AUTH_CONTEXT_PATH` | `/devsuite/static/auth` | Base context for auth endpoints |
| `AUTH_LOGIN_ENDPOINT` | `<AUTH_CONTEXT_PATH>/j_spring_security_check` | Login endpoint override |
| `AUTH_LOGOUT_ENDPOINT` | `<AUTH_CONTEXT_PATH>/j_spring_security_logout` | Logout endpoint override |
| `AUTH_LOGOUT_EACH_ITERATION` | `false` | Optional per-iteration logout |
| `AUTH_STICKY_SESSIONS` | `true` | Controls `noCookiesReset` behavior |
| `AUTH_DEBUG` | `false` | Emits auth debug logs |
| `AUTH_CONTEXT_API_PATH` | `/devsuite/web/api/context` | Base path for the context invalidation API (`/invalidate`, `/check`) |
| `AUTH_SESSION_DURATION_SECONDS` | `0` | Per-VU session lifetime in seconds; `0` = disabled. When elapsed, the invalidation cycle replaces the current iteration's scenario work, then re-login occurs on the next iteration |
| `ENABLE_FAILURE_DIAGNOSTICS` | `true` | Enable structured failure diagnostics logs (`false` disables diagnostics output) |
| `FAILURE_LOG_LIMIT_PER_VU` | `0` | Max diagnostic failure logs per VU (`0` = unlimited) |
| `FAILURE_BODY_SNIPPET_LENGTH` | `1024` (min 80) | Response body snippet length in diagnostics |
| `DEBUG_CONFIG_OUTPUT` | `false` | Print fully-resolved config and effective k6 options at startup |
| `CREATE_SEED_RECORDS` | `false` | Create seed records in setup phase; `false` = use existing records |
| `SEED_RECORD_MAX` | `100000` | Upper bound for random record selection when `CREATE_SEED_RECORDS` is false |
| `CRUD_WEIGHT` | `0.9` | Share of unified-scenario iterations dispatched to CRUD operations; all six weights must sum to 1.0 |
| `NOOP_WEIGHT` | `0.1` | Share of iterations dispatched to NOOP (objects service) operations |
| `ANOMALY_SIMULATE_WEIGHT` | `0.0` | Share dispatched to simulate anomalies; disabled by default |
| `ANOMALY_LEAK_WEIGHT` | `0.0` | Share dispatched to leak anomalies; disabled by default |
| `ANOMALY_DISRUPT_WEIGHT` | `0.0` | Share dispatched to disrupt anomalies; disabled by default |
| `ANOMALY_FILES_WEIGHT` | `0.0` | Share dispatched to files anomalies; disabled by default |

## 4) Script Family Summary

- CRUD scripts (`scripts/crud/*.js`): profile scenarios + `API_PATH`
- Objects scripts (`scripts/objects/*.js`): profile scenarios (no script-local env vars)
- Procedures scripts (`scripts/procedures/*.js`): profile scenarios (no script-local env vars)

If you want, I can also generate a machine-readable version (`JSON`/`CSV`) with one row per launcher scenario and all resolved option fields.