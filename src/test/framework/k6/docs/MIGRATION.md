# Migration Guide: Legacy `--env` Flags → Config Files

This guide maps every legacy `k6 run --env VAR=value` invocation to its
equivalent config-file approach.  The config-driven system (introduced in
Phase 1–3 of the CONFIG_RUNNER_PLAN) is the preferred way to run all
launchers.

---

## Why migrate?

| Concern | Legacy `--env` | Config file |
|---|---|---|
| Repeatability | Flags differ between runs | One file, version-controlled |
| Secrets | Password visible in shell history | Keep in a local untracked file |
| Inheritance | Must repeat common values | Use `extends` to build on a base |
| Validation | Silent bad values | Validator rejects wrong types on startup |
| Dry-run | No log of effective config | `logResolvedConfig` prints full config at start |

---

## Quick-start equivalents

### 1 - Run with the built-in smoke profile

**Legacy**
```bash
k6 run --env PROFILE=smoke scripts/launchUnifiedScenario.js
```

**Config file** - use the canonical reference config:
```bash
k6 run --env CONFIG_FILE=configs/profiles/smoke.json scripts/launchUnifiedScenario.js
```

### 2 - Run with the built-in load profile

**Legacy**
```bash
k6 run --env PROFILE=load scripts/launchUnifiedScenario.js
```

**Config file**
```bash
k6 run --env CONFIG_FILE=configs/profiles/load.json scripts/launchUnifiedScenario.js
```

All five canonical reference configs are in `configs/profiles/`:
`simple.json`, `smoke.json`, `load.json`, `stress.json`, `chaos.json`.

---

## Overriding individual values

### 3 - Change `MAX_VUS` for a load run

**Legacy**
```bash
k6 run --env PROFILE=load --env MAX_VUS=20 scripts/launchUnifiedScenario.js
```

**Config file** - copy the reference config and edit:
```jsonc
// configs/load-20vu.json
{
  "meta": { "name": "load-20vu", "description": "Load run with 20 VUs" },
  "extends": "configs/profiles/load.json",
  "run": { "profile": "load" },
  "env": {
    "MAX_VUS": 20
  }
}
```
```bash
k6 run --env CONFIG_FILE=configs/load-20vu.json scripts/launchUnifiedScenario.js
```

Fields in the current config override the base config supplied by `extends`.

### 4 - Change the target server URL

**Legacy**
```bash
k6 run --env BASE_URL=http://myserver:7780 scripts/launchUnifiedScenario.js
```

**Config file**
```jsonc
// configs/smoke-myserver.json
{
  "meta": { "name": "smoke-myserver" },
  "extends": "configs/profiles/smoke.json",
  "run": { "profile": "smoke" },
  "env": {
    "BASE_URL": "http://myserver:7780"
  }
}
```
```bash
k6 run --env CONFIG_FILE=configs/smoke-myserver.json scripts/launchUnifiedScenario.js
```

> The `BASE_URL` **must** be a non-empty JSON string.  The validator rejects
> an empty string or a non-string value.

### 5 - Enable logout after each iteration

**Legacy**
```bash
k6 run --env PROFILE=smoke --env AUTH_LOGOUT_EACH_ITERATION=true scripts/launchAuthOnly.js
```

**Config file** - use the starter config, or create your own:
```bash
k6 run --env CONFIG_FILE=configs/auth-logout-smoke.json scripts/launchAuthOnly.js
```

Or create a custom config:
```jsonc
{
  "meta": { "name": "smoke-logout" },
  "extends": "configs/profiles/smoke.json",
  "run": { "profile": "smoke" },
  "env": {
    "AUTH_LOGOUT_EACH_ITERATION": true
  }
}
```

> **Important:** boolean fields (`AUTH_REQUIRED`, `AUTH_LOGOUT_EACH_ITERATION`,
> `AUTH_STICKY_SESSIONS`, `AUTH_DEBUG`, `DEBUG_CONFIG_OUTPUT`, `ENABLE_FAILURE_DIAGNOSTICS`) must be
> JSON booleans (`true` / `false`), **not** quoted strings (`"true"`).
> The validator will reject quoted booleans with a clear error message.

### 6 - Enable auth debugging

**Legacy**
```bash
k6 run --env PROFILE=smoke --env AUTH_DEBUG=true scripts/launchAuthOnly.js
```

**Config file** - use the starter config:
```bash
k6 run --env CONFIG_FILE=configs/auth-debug-smoke.json scripts/launchAuthOnly.js
```

### 7 - Stress test with 100 VUs for 60 minutes

**Legacy**
```bash
k6 run --env PROFILE=stress --env MAX_VUS=100 --env DURATION=60 \
       --env ENABLE_FAILURE_DIAGNOSTICS=true scripts/launchEmployeeHR.js
```

**Config file** - use the starter config:
```bash
k6 run --env CONFIG_FILE=configs/stress-capacity.json scripts/launchEmployeeHR.js
```

Or create your own by extending the stress profile:
```jsonc
{
  "meta": { "name": "stress-100vu-60min" },
  "extends": "configs/profiles/stress.json",
  "run": { "profile": "stress" },
  "env": {
    "MAX_VUS": 100,
    "DURATION": 60,
    "ENABLE_FAILURE_DIAGNOSTICS": true
  }
}
```

### 8 - Limit scenarios to a subset

**Legacy**
```bash
k6 run --env PROFILE=smoke --env SCENARIOS_INCLUDE=state,customer scripts/launchUnifiedScenario.js
```

**Config file**
```jsonc
{
  "meta": { "name": "smoke-subset" },
  "extends": "configs/profiles/smoke.json",
  "run": { "profile": "smoke" },
  "scenarios": {
    "include": ["state", "customer"]
  }
}
```

---

## Complete `env` key reference

| Key | Type | Legacy `--env` example | Config file value |
|-----|------|------------------------|-------------------|
| `BASE_URL` | string | `BASE_URL=http://host:7780` | `"BASE_URL": "http://host:7780"` |
| `MAX_VUS` | number | `MAX_VUS=10` | `"MAX_VUS": 10` |
| `MAX_ITERATIONS` | number | `MAX_ITERATIONS=50` | `"MAX_ITERATIONS": 50` |
| `DURATION` | number | `DURATION=30` | `"DURATION": 30` |
| `IDLE_STAGE_CHANCE` | number (0–1) | `IDLE_STAGE_CHANCE=0.1` | `"IDLE_STAGE_CHANCE": 0.1` |
| `SCENARIO_STAGGER_SECONDS` | number | `SCENARIO_STAGGER_SECONDS=1` | `"SCENARIO_STAGGER_SECONDS": 1` |
| `MIN_THINK_TIME` | number | `MIN_THINK_TIME=0.5` | `"MIN_THINK_TIME": 0.5` |
| `MAX_THINK_TIME` | number | `MAX_THINK_TIME=2` | `"MAX_THINK_TIME": 2` |
| `SEED_RECORD_RATIO` | number | `SEED_RECORD_RATIO=2` | `"SEED_RECORD_RATIO": 2` |
| `AUTH_REQUIRED` | boolean | `AUTH_REQUIRED=true` | `"AUTH_REQUIRED": true` |
| `AUTH_USERNAME_PREFIX` | string | `AUTH_USERNAME_PREFIX=oels-vu` | `"AUTH_USERNAME_PREFIX": "oels-vu"` |
| `AUTH_PASSWORD` | string | `AUTH_PASSWORD=secret` | `"AUTH_PASSWORD": "secret"` |
| `AUTH_CONTEXT_PATH` | string | `AUTH_CONTEXT_PATH=/devsuite/static/auth` | `"AUTH_CONTEXT_PATH": "/devsuite/static/auth"` |
| `AUTH_LOGIN_ENDPOINT` | string | `AUTH_LOGIN_ENDPOINT=/…/j_spring_security_check` | `"AUTH_LOGIN_ENDPOINT": "/…/j_spring_security_check"` |
| `AUTH_LOGOUT_ENDPOINT` | string | `AUTH_LOGOUT_ENDPOINT=/…/j_spring_security_logout` | `"AUTH_LOGOUT_ENDPOINT": "/…/j_spring_security_logout"` |
| `AUTH_LOGOUT_EACH_ITERATION` | boolean | `AUTH_LOGOUT_EACH_ITERATION=true` | `"AUTH_LOGOUT_EACH_ITERATION": true` |
| `AUTH_STICKY_SESSIONS` | boolean | `AUTH_STICKY_SESSIONS=true` | `"AUTH_STICKY_SESSIONS": true` |
| `AUTH_DEBUG` | boolean | `AUTH_DEBUG=true` | `"AUTH_DEBUG": true` |
| `ENABLE_FAILURE_DIAGNOSTICS` | boolean | `ENABLE_FAILURE_DIAGNOSTICS=true` | `"ENABLE_FAILURE_DIAGNOSTICS": true` |
| `FAILURE_LOG_LIMIT_PER_VU` | number | `FAILURE_LOG_LIMIT_PER_VU=10` | `"FAILURE_LOG_LIMIT_PER_VU": 10` |
| `FAILURE_BODY_SNIPPET_LENGTH` | number | `FAILURE_BODY_SNIPPET_LENGTH=300` | `"FAILURE_BODY_SNIPPET_LENGTH": 300` |
| `API_PATH` | string | `API_PATH=/data/state` | `"API_PATH": "/data/state"` |
| `AUTH_CONTEXT_API_PATH` | string | `AUTH_CONTEXT_API_PATH=/devsuite/web/api/context` | `"AUTH_CONTEXT_API_PATH": "/devsuite/web/api/context"` |
| `AUTH_SESSION_DURATION_SECONDS` | number | `AUTH_SESSION_DURATION_SECONDS=3600` | `"AUTH_SESSION_DURATION_SECONDS": 3600` |
| `CREATE_SEED_RECORDS` | boolean | `CREATE_SEED_RECORDS=false` | `"CREATE_SEED_RECORDS": false` |
| `SEED_RECORD_MAX` | number | `SEED_RECORD_MAX=50000` | `"SEED_RECORD_MAX": 50000` |
| `DEBUG_CONFIG_OUTPUT` | boolean | `DEBUG_CONFIG_OUTPUT=true` | `"DEBUG_CONFIG_OUTPUT": true` |
| `CRUD_WEIGHT` | number (0–1) | `CRUD_WEIGHT=0.7` | `"CRUD_WEIGHT": 0.7` |
| `NOOP_WEIGHT` | number (0–1) | `NOOP_WEIGHT=0.2` | `"NOOP_WEIGHT": 0.2` |
| `ANOMALY_SIMULATE_WEIGHT` | number (0–1) | `ANOMALY_SIMULATE_WEIGHT=0.1` | `"ANOMALY_SIMULATE_WEIGHT": 0.1` |
| `ANOMALY_LEAK_WEIGHT` | number (0–1) | `ANOMALY_LEAK_WEIGHT=0.0` | `"ANOMALY_LEAK_WEIGHT": 0.0` |
| `ANOMALY_DISRUPT_WEIGHT` | number (0–1) | `ANOMALY_DISRUPT_WEIGHT=0.0` | `"ANOMALY_DISRUPT_WEIGHT": 0.0` |
| `ANOMALY_FILES_WEIGHT` | number (0–1) | `ANOMALY_FILES_WEIGHT=0.0` | `"ANOMALY_FILES_WEIGHT": 0.0` |

> **Type enforcement**: numeric fields must be JSON numbers (not `"20"`); boolean
> fields must be JSON booleans (not `"true"`).  The config validator will throw
> a descriptive error if the wrong type is provided.

---

## Deferred items

- **CI linting**: A lint pass that validates every config file in `configs/` on
  every pull request has been deferred until CI infrastructure (e.g., GitHub
  Actions) is established.

- **Schema unit tests**: Automated tests that exercise the validator with
  invalid configs (wrong types, unknown keys, out-of-range values) have been
  deferred until the team selects a JavaScript test framework (Jest, node:test,
  or k6-native).
