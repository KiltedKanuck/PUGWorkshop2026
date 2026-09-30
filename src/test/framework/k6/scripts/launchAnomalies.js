/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 *
 * k6 scenario launcher for all Anomaly service tests.
 *
 * NOTE: Two endpoints intentionally return non-2xx status codes:
 *   - /anomaly/code/quit  → HTTP 500 (unhandled QUIT condition)
 *   - /anomaly/code/stop  → HTTP 408 (STOP condition / request timeout)
 * Because of this, http_req_failed is omitted from the global thresholds.
 * Correctness is validated at the check level within each individual script.
 *
 * Usage:
 *   k6 run --env CONFIG_FILE=configs/smoke-local.json    launchAnomalies.js
 *   k6 run --env CONFIG_FILE=configs/load-baseline.json  launchAnomalies.js
 *   k6 run                                               launchAnomalies.js  (smoke defaults)
 */

import { buildLauncherScenarioFromProfile } from '../common/scenarios.js';
import { loadConfig, logResolvedConfig } from '../common/configLoader.js';
import { setProfile, applyEnvConfig }    from '../common/config.js';
import { applyAuthConfig, AUTH_STICKY_SESSIONS } from '../common/auth.js';
import { applyDiagnosticsConfig }        from '../common/diagnostics.js';
import { createHandleSummary }           from '../common/summary.js';

export const handleSummary = createHandleSummary('launchAnomalies');

import { default as testCodeBusy }      from './anomaly/codeBusy.js';
import { default as testCodeQuit }      from './anomaly/codeQuit.js';
import { default as testCodeStop }      from './anomaly/codeStop.js';
import { default as testDbDisconnect }  from './anomaly/dbDisconnect.js';
import { default as testLeakBuffer }    from './anomaly/leakBuffer.js';
import { default as testLeakHandle }    from './anomaly/leakHandle.js';
import { default as testLeakMemptr }    from './anomaly/leakMemptr.js';
import { default as testLeakObject }    from './anomaly/leakObject.js';

// ---------------------------------------------------------------------------
// Config loading - must happen before export const options is evaluated.
// ---------------------------------------------------------------------------
const _rawConfig = __ENV.CONFIG_FILE ? open(__ENV.CONFIG_FILE) : null;
let _baseConfig = null;
if (_rawConfig) {
  try {
    const _peek = JSON.parse(_rawConfig);
    if (_peek.extends) { _baseConfig = open(_peek.extends); }
  } catch (_) {}
}
const _cfg = loadConfig(_rawConfig, _baseConfig);

setProfile(_cfg.run.profile);
applyEnvConfig(_cfg.env);
applyAuthConfig(_cfg.env);
applyDiagnosticsConfig(_cfg.env);

const { systemTags, ...scenario } = buildLauncherScenarioFromProfile();

export const options = {
  noCookiesReset: AUTH_STICKY_SESSIONS,
  setupTimeout:    _cfg.options.setupTimeout    || '5m',
  teardownTimeout: _cfg.options.teardownTimeout || '5m',
  tags: { launcher: 'launchAnomalies', ...(_cfg.options.tags || {}) },
  scenarios: {
    AnomalyCodeBusy:     { ...scenario, exec: 'testCodeBusy' },
    AnomalyCodeQuit:     { ...scenario, exec: 'testCodeQuit' },
    AnomalyCodeStop:     { ...scenario, exec: 'testCodeStop' },
    AnomalyDbDisconnect: { ...scenario, exec: 'testDbDisconnect' },
    AnomalyLeakBuffer:   { ...scenario, exec: 'testLeakBuffer' },
    AnomalyLeakHandle:   { ...scenario, exec: 'testLeakHandle' },
    AnomalyLeakMemptr:   { ...scenario, exec: 'testLeakMemptr' },
    AnomalyLeakObject:   { ...scenario, exec: 'testLeakObject' },
  },
  thresholds: {
    // http_req_failed is intentionally omitted: codeQuit (500) and codeStop (408)
    // return non-2xx by design. Use check-level results to verify correct behavior.
    checks: ['rate==1'],
    ...(_cfg.options.thresholds || {}),
  },
};
logResolvedConfig(_cfg, options);

// Re-export imported defaults so k6 can resolve the exec names above.
export {
  testCodeBusy,
  testCodeQuit,
  testCodeStop,
  testDbDisconnect,
  testLeakBuffer,
  testLeakHandle,
  testLeakMemptr,
  testLeakObject,
};
