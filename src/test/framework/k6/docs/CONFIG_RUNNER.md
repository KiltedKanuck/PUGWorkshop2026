# Config-Driven Runner Guide

This document covers the config-driven execution model introduced in Phase 1 of the
[CONFIG_RUNNER_PLAN.md](CONFIG_RUNNER_PLAN.md). It replaces direct `--env` flag usage
for `scripts/launchUnifiedScenario.js` and `scripts/launchMultiScenario.js`.

---

## Quick Start

```bat
k6 run --env CONFIG_FILE=configs/smoke-local.json    scripts/launchUnifiedScenario.js
k6 run --env CONFIG_FILE=configs/load-baseline.json  scripts/launchUnifiedScenario.js
k6 run --env CONFIG_FILE=configs/chaos-60m.json      scripts/launchMultiScenario.js
```

Running without `CONFIG_FILE` is allowed and produces a safe smoke check:

```bat
k6 run scripts/launchUnifiedScenario.js   # warns + runs smoke defaults
```

---

## Starter Config Files

| File | Profile | VUs | Iterations / Duration |
|------|---------|-----|-----------------------|
| `configs/smoke-local.json` | smoke | 1 | 1 iteration |
| `configs/load-baseline.json` | load | 20 | 100 iterations |
| `configs/chaos-60m.json` | chaos | 100 | 60 minutes |

---

## Config File Schema

All config files are JSON. The full schema shape is:

```json
{
  "meta": {
    "name": "my-config",
    "description": "What this config does",
    "version": 1
  },
  "run": {
    "profile": "load"
  },
  "env": {
    "BASE_URL": "http://host:7780",
    "MAX_VUS": 20,
    "MAX_ITERATIONS": 100,
    "DURATION": 10,
    "IDLE_STAGE_CHANCE": 0.05,
    "SCENARIO_STAGGER_SECONDS": 0.5,
    "MIN_THINK_TIME": 0.1,
    "MAX_THINK_TIME": 1.0,
    "CREATE_SEED_RECORDS": false,
    "SEED_RECORD_MAX": 100000,
    "SEED_RECORD_RATIO": 1,
    "AUTH_REQUIRED": true,
    "AUTH_USERNAME_PREFIX": "oels-vu",
    "AUTH_PASSWORD": "password",
    "AUTH_CONTEXT_PATH": "/loadsuite/static/auth",
    "AUTH_LOGIN_ENDPOINT": "",
    "AUTH_LOGOUT_ENDPOINT": "",
    "AUTH_LOGOUT_EACH_ITERATION": false,
    "AUTH_STICKY_SESSIONS": true,
    "AUTH_DEBUG": false,
    "AUTH_CONTEXT_API_PATH": "/loadsuite/web/api/context",
    "AUTH_SESSION_DURATION_SECONDS": 0,
    "ENABLE_FAILURE_DIAGNOSTICS": true,
    "FAILURE_LOG_LIMIT_PER_VU": 0,
    "FAILURE_BODY_SNIPPET_LENGTH": 1024,
    "DEBUG_CONFIG_OUTPUT": false,
    "API_PATH": "",
    "CREATE_SEED_RECORDS": false,
    "SEED_RECORD_MAX": 100000,
    "CRUD_WEIGHT": 0.9,
    "NOOP_WEIGHT": 0.1,
    "ANOMALY_SIMULATE_WEIGHT": 0.0,
    "ANOMALY_LEAK_WEIGHT": 0.0,
    "ANOMALY_DISRUPT_WEIGHT": 0.0,
    "ANOMALY_FILES_WEIGHT": 0.0
  },
  "options": {
    "setupTimeout": "20m",
    "teardownTimeout": "20m",
    "tags": { "suite": "oels" },
    "thresholds": {
      "http_req_duration": ["p(90)<1000", "p(95)<2000", "p(99)<4000"]
    }
  }
}
```

### `env` Field Reference

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `BASE_URL` | string | AWS host:7780 | Target server for all API calls |
| `MAX_VUS` | integer ≥ 2 | 20 | VU ceiling for load / stress / chaos |
| `MAX_ITERATIONS` | integer ≥ 1 | 100 | Total shared iterations for load / smoke / simple |
| `DURATION` | integer ≥ 5 | 10 | Stage duration base in minutes |
| `IDLE_STAGE_CHANCE` | float 0–1 | 0.05 | Fraction of chaos stages that ramp to 0 VUs |
| `SCENARIO_STAGGER_SECONDS` | float ≥ 0 | 0.5 | Start-time gap between chaos scenarios |
| `MIN_THINK_TIME` | float ≥ 0 | 0.1 | Iteration pause lower bound in seconds |
| `MAX_THINK_TIME` | float ≥ 0 | 1.0 | Chaos-only think time upper bound in seconds |
| `SEED_RECORD_RATIO` | integer ≥ 1 | 1 | VUs-per-record ratio (higher = more contention) |
| `AUTH_REQUIRED` | boolean | true | Require per-VU authentication |
| `AUTH_USERNAME_PREFIX` | string | `oels-vu` | Username built as `<prefix>-<VU_ID>` |
| `AUTH_PASSWORD` | string | `password` | Password for all VU logins |
| `AUTH_CONTEXT_PATH` | string | `/loadsuite/static/auth` | Base path for auth endpoints |
| `AUTH_LOGIN_ENDPOINT` | string | derived from context path | Override login endpoint |
| `AUTH_LOGOUT_ENDPOINT` | string | derived from context path | Override logout endpoint |
| `AUTH_LOGOUT_EACH_ITERATION` | boolean | false | Logout after every iteration |
| `AUTH_STICKY_SESSIONS` | boolean | true | Preserve session cookies across iterations |
| `AUTH_DEBUG` | boolean | false | Emit `[auth]` debug logs |
| `AUTH_CONTEXT_API_PATH` | string | `/loadsuite/web/api/context` | Base path for the context invalidation API (`/invalidate`, `/check`) |
| `AUTH_SESSION_DURATION_SECONDS` | integer ≥ 0 | 0 | Per-VU session lifetime in seconds; `0` = disabled. When elapsed, the invalidation cycle runs as the full iteration (no scenario work), then re-login occurs on the next iteration |
| `ENABLE_FAILURE_DIAGNOSTICS` | boolean | true | Enable structured failure event logs (`false` disables diagnostics output) |
| `FAILURE_LOG_LIMIT_PER_VU` | integer ≥ 0 | 0 | Max failure logs per VU; `0` = unlimited |
| `FAILURE_BODY_SNIPPET_LENGTH` | integer ≥ 80 | 1024 | Response body chars captured in diagnostics |
| `API_PATH` | string | per-script default | Override CRUD endpoint path (advanced) |
| `CREATE_SEED_RECORDS` | boolean | false | Create seed records in setup phase; `false` = use existing records up to `SEED_RECORD_MAX` |
| `SEED_RECORD_MAX` | integer ≥ 1 | 100000 | Upper bound for random record selection when `CREATE_SEED_RECORDS` is false |
| `DEBUG_CONFIG_OUTPUT` | boolean | false | Print fully-resolved config and effective k6 options at startup |
| `CRUD_WEIGHT` | float 0–1 | 0.9 | Share of unified-scenario iterations dispatched to CRUD operations; all six weights must sum to 1.0 |
| `NOOP_WEIGHT` | float 0–1 | 0.1 | Share of unified-scenario iterations dispatched to NOOP (objects service) operations |
| `ANOMALY_SIMULATE_WEIGHT` | float 0–1 | 0.0 | Share dispatched to simulate anomalies (e.g. codeBusy); disabled by default |
| `ANOMALY_LEAK_WEIGHT` | float 0–1 | 0.0 | Share dispatched to leak anomalies (leakBuffer, leakHandle, etc.); disabled by default |
| `ANOMALY_DISRUPT_WEIGHT` | float 0–1 | 0.0 | Share dispatched to disrupt anomalies (dbDisconnect, codeQuit, codeStop); disabled by default |
| `ANOMALY_FILES_WEIGHT` | float 0–1 | 0.0 | Share dispatched to files anomalies (osCommandData, inputThroughData); disabled by default |

> **Note:** `AUTH_LOGIN_ENDPOINT` and `AUTH_LOGOUT_ENDPOINT` are automatically derived
> from `AUTH_CONTEXT_PATH` when left as empty strings (`""`). Only set them explicitly
> if your server uses non-standard auth endpoint paths.

---

## Changing the Target Server

Set `BASE_URL` in the config file:

```json
"env": {
  "BASE_URL": "http://my-local-server:7780"
}
```

The `BASE_URL` value applies to all API calls and all scenarios in the run.

---

## Threshold Overrides

You can override default profile thresholds from the config file using `options.thresholds`.

Format:

```json
"options": {
  "thresholds": {
    "<metric_name>": ["<expression>", "<expression>"]
  }
}
```

Example (multi-percentile latency gates):

```json
"options": {
  "thresholds": {
    "http_req_duration": [
      "p(90)<1000",
      "p(95)<2000",
      "p(99)<4000"
    ],
    "http_req_failed": ["rate<0.02"]
  }
}
```

Example (tag-scoped chaos gate in multi-scenario launcher):

```json
"options": {
  "thresholds": {
    "http_req_duration{profile:chaos}": ["p(95)<3500"],
    "checks{profile:chaos}": ["rate>=0.80"]
  }
}
```

Notes:

1. Any metric key you provide replaces that metric's default threshold list.
2. Metrics not specified in `options.thresholds` keep their built-in defaults.
3. In auth-only launcher runs, auth-specific defaults are applied first, then
   `options.thresholds` overrides are applied last.

---

## Profiles

Set `run.profile` to one of:

| Profile | Executor | Typical use |
|---------|----------|-------------|
| `smoke` | shared-iterations (1 VU, 1 iter) | Pre-commit sanity check |
| `simple` | shared-iterations (1 VU, 1 iter) | Safe single-pass check |
| `load` | shared-iterations (`MAX_VUS` VUs, `MAX_ITERATIONS` iters) | Baseline throughput |
| `stress` | ramping-vus (staircase to `MAX_VUS`) | Saturation (soak) point identification |
| `chaos` | ramping-vus (random stages for `DURATION` minutes) | Resilience / spike testing |

---

## Validation Rules

The config loader validates all values before any VU or setup phase starts.
If validation fails, k6 aborts with a clear error message listing every problem found.

1. **Required sections:** `meta`, `run`, `env` must be present.
2. **Profile:** `run.profile` must be one of `smoke`, `simple`, `load`, `stress`, `chaos`.
3. **Numeric ranges** (see table above).
4. **Cross-field:** `MAX_THINK_TIME >= MIN_THINK_TIME`.
5. **Unknown keys:** Any unrecognized top-level, `run`, `env`, `meta`, or `options`, key causes a validation failure with the list of valid keys.
6. **Threshold shape:** `options.thresholds` must be an object where each value is a
  non-empty array of strings.

### Example validation error

```
Error: [configLoader] Config validation failed:
  - env.MAX_VUS must be >= 2; got: 1
  - Unknown env key: "PROFIL". Valid keys: BASE_URL, MAX_VUS, ...
```

---

## Safe Defaults (no CONFIG_FILE)

Running a launcher without `--env CONFIG_FILE` prints a visible warning and applies
smoke defaults: 1 VU, 1 iteration. This prevents accidentally running a full load test.

```
WARN [config] No CONFIG_FILE provided - running smoke defaults (1 VU, 1 iteration).
              To run a real test: k6 run --env CONFIG_FILE=configs/load-baseline.json <launcher>.js
```

---

## Precedence

1. Config file values (highest)
2. Built-in safe defaults (lowest)

Individual `--env` flags for suite settings (`PROFILE`, `MAX_VUS`, `AUTH_*`, etc.) are
**not** read by `scripts/launchUnifiedScenario.js` or `scripts/launchMultiScenario.js`. All configuration
must be in the JSON config file. The only accepted `--env` flag is `CONFIG_FILE`.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `Config validation failed: Unknown env key` | Typo in a field name | Check the field name spelling against the reference table |
| `Config validation failed: env.MAX_VUS must be >= 2` | `MAX_VUS: 1` in config | Set `MAX_VUS: 2` (smoke profile ignores this value anyway) |
| `Failed to parse CONFIG_FILE as JSON` | Syntax error in JSON | Validate the file with a JSON linter |
| Warning printed multiple times | Normal - k6 evaluates modules once per VU context | Not an error; ignore |
| Auth fails with no CONFIG_FILE | Default credentials don't match server | Provide a config file with correct `AUTH_*` values |
