/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 *
 * k6 scenario launcher - System & Configuration group (8 CRUD tests run simultaneously).
 *
 * All tests in this group are data-independent of each other - no FK relationships
 * exist between state, localdefault, systemfile, auditheader, auditdetail,
 * contextheader, contextdetail, or replqueue seed data. Setup and teardown
 * can run in any order.
 *
 * Usage:
 *   k6 run --env CONFIG_FILE=configs/smoke-local.json    launchSystemConfig.js
 *   k6 run --env CONFIG_FILE=configs/load-baseline.json  launchSystemConfig.js
 *   k6 run                                               launchSystemConfig.js  (smoke defaults)
 */

import { buildLauncherScenarioFromProfile, buildTopLevelProfileOptions } from '../common/scenarios.js';
import { loadConfig, logResolvedConfig } from '../common/configLoader.js';
import { setProfile, applyEnvConfig }    from '../common/config.js';
import { applyAuthConfig }               from '../common/auth.js';
import { applyDiagnosticsConfig }        from '../common/diagnostics.js';
import { createHandleSummary }           from '../common/summary.js';

export const handleSummary = createHandleSummary('launchSystemConfig');

import { default as stateTest,        setup as setupState,        teardown as teardownState        } from './crud/state.js';
import { default as localdefaultTest, setup as setupLocaldefault, teardown as teardownLocaldefault } from './crud/localdefault.js';

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

const scenario = buildLauncherScenarioFromProfile();
const topLevelOptions = buildTopLevelProfileOptions();

export const options = {
  ...topLevelOptions,
  setupTimeout:    _cfg.options.setupTimeout    || '20m',
  teardownTimeout: _cfg.options.teardownTimeout || '20m',
  tags: { launcher: 'launchSystemConfig', ...(_cfg.options.tags || {}) },
  scenarios: {
    State:        { ...scenario, exec: 'State'        },
    Localdefault: { ...scenario, exec: 'Localdefault' },
  },
  thresholds: {
    http_req_failed: ['rate<0.05'],
    checks:          ['rate>=0.95'],
    ...(_cfg.options.thresholds || {}),
  },
};
logResolvedConfig(_cfg, options);

/**
 * Combined setup - seeds all System & Configuration data.
 * No FK dependencies; all setups are independent.
 * @returns {object} Namespaced setup data keyed by test name.
 */
export function setup() {
  return {
    state:        setupState(),
    localdefault: setupLocaldefault(),
  };
}

// Wrapper scenario functions - each receives the full combined data object
// and passes only its own namespace slice to the underlying test default.
export function State(data)        { stateTest(data.state);               }
export function Localdefault(data) { localdefaultTest(data.localdefault); }

/**
 * Combined teardown - removes all seeded System & Configuration data.
 * No FK constraints; order does not matter.
 * @param {object} data Combined setup data.
 */
export function teardown(data) {
  teardownState(data.state);
  teardownLocaldefault(data.localdefault);
}