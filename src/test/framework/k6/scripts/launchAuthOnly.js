/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 *
 * k6 authentication-only launcher.
 *
 * Purpose:
 * - isolate PASOE/Tomcat login behavior from all CRUD/object test traffic
 * - create one authenticated session per Virtual User using deterministic usernames
 * - optionally log out each Virtual User after login for logout validation
 * - validate authenticated sessions with a "ping" call
 *
 * Usage:
 *   k6 run --env CONFIG_FILE=configs/auth-logout-smoke.json launchAuthOnly.js
 *   k6 run --env CONFIG_FILE=configs/load-baseline.json     launchAuthOnly.js
 *   k6 run                                                  launchAuthOnly.js  (smoke defaults)
 */

import { check } from 'k6';
import { runAuthOnly, validateAuthenticatedSession, logoutVirtualUserSession } from '../common/auth.js';
import { buildScenarioFromProfile } from '../common/scenarios.js';
import { labelCheckName } from '../common/utils.js';
import { loadConfig, logResolvedConfig } from '../common/configLoader.js';
import { setProfile, applyEnvConfig }    from '../common/config.js';
import { applyAuthConfig }               from '../common/auth.js';
import { applyDiagnosticsConfig }        from '../common/diagnostics.js';
import { createHandleSummary }           from '../common/summary.js';

export const handleSummary = createHandleSummary('launchAuthOnly');

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

// Build the base VU/iteration options from the selected profile (smoke, load, stress, etc.).
// The profile options also include any default thresholds, which we override below because
// auth-only tests are inherently slower than CRUD tests and have different expectations.
const _profileOptions = buildScenarioFromProfile();

export const options = {
  // Copy all default options fields (executor, vus, iterations, stages, etc.)
  ..._profileOptions,
  setupTimeout:    _cfg.options.setupTimeout    || '20m',
  teardownTimeout: _cfg.options.teardownTimeout || '20m',
  // Override the thresholds object only. This copies the original (default) properties
  // first, while replacing individual metric thresholds that better suit our needs.
  thresholds: {
    ..._profileOptions.thresholds,        // inherit http_req_failed and other defaults
    http_req_duration: ['p(95)<10000'],   // auth roundtrips are slower than CRUD; allow 10s
    ...(_cfg.options.thresholds || {}),   // allow config-driven per-metric overrides
  },
  tags: {
    ..._profileOptions.tags,
    ...(_cfg.options.tags || {}),
    launcher: 'launchAuthOnly',
  },
};
logResolvedConfig(_cfg, options);

export default function authOnlyScenario() {
  const result = runAuthOnly();

  check(result, {
    [labelCheckName('default', 'auth username assigned')]: (r) => typeof r.username === 'string' && r.username.length > 0,
  });

  // Validate the authenticated session by making an API call
  validateAuthenticatedSession(result.username);

  if (_cfg.env.AUTH_LOGOUT_EACH_ITERATION === true) {
    logoutVirtualUserSession();
  }
}