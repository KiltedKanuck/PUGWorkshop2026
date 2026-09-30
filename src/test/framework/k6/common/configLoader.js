/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 *
 * Config-driven runner: JSON config loader and validator.
 *
 * Usage in a launcher (init context):
 *
 *   import { loadConfig, logResolvedConfig } from './common/configLoader.js';
 *   import { setProfile, applyEnvConfig }    from './common/config.js';
 *   import { applyAuthConfig }               from './common/auth.js';
 *   import { applyDiagnosticsConfig }        from './common/diagnostics.js';
 *
 *   const _rawConfig = __ENV.CONFIG_FILE ? open(__ENV.CONFIG_FILE) : null;
 *   let _baseConfig = null;
 *   if (_rawConfig) {
 *     try {
 *       const _peek = JSON.parse(_rawConfig);
 *       if (_peek.extends) { _baseConfig = open(_peek.extends); }
 *     } catch (_) {}
 *   }
 *   const _cfg = loadConfig(_rawConfig, _baseConfig);
 *
 *   setProfile(_cfg.run.profile);
 *   applyEnvConfig(_cfg.env);
 *   applyAuthConfig(_cfg.env);
 *   applyDiagnosticsConfig(_cfg.env);
 *
 *   export const options = { ...buildScenarioFromProfile(), ... };
 *
 * See CONFIG_RUNNER.md for full documentation.
 */

// ---------------------------------------------------------------------------
// Safe Defaults - used when no CONFIG_FILE is provided.
// These produce the safest possible run: smoke, 1 VU, 1 iteration.
// Note: Some properties may be applied by this safe config which are not used
// by the smoke profile, but are set to ensure a sane default is available.
// ---------------------------------------------------------------------------

const SAFE_DEFAULTS = Object.freeze({
  meta: {
    name: 'safe-default',
    description: 'Auto-applied safe defaults (no CONFIG_FILE was provided)',
    version: 1,
  },
  run: {
    profile: 'smoke',
  },
  env: {
    BASE_URL:                     'http://127.0.0.1:7780',
    MAX_VUS:                      1,
    MAX_ITERATIONS:               1,
    DURATION:                     5,
    IDLE_STAGE_CHANCE:            0.05,
    SCENARIO_STAGGER_SECONDS:     0.5,
    MIN_THINK_TIME:               0,
    MAX_THINK_TIME:               0,
    CREATE_SEED_RECORDS:          false,
    SEED_RECORD_MAX:              100000,
    SEED_RECORD_RATIO:            1,

    CRUD_WEIGHT:                  0.9,
    NOOP_WEIGHT:                  0.1,
    ANOMALY_DISRUPT_WEIGHT:       0.0,
    ANOMALY_FILES_WEIGHT:         0.0,
    ANOMALY_LEAK_WEIGHT:          0.0,
    ANOMALY_SIMULATE_WEIGHT:      0.0,

    AUTH_REQUIRED:                true,
    AUTH_USERNAME_PREFIX:         'oels-vu',
    AUTH_PASSWORD:                'password',
    AUTH_CONTEXT_PATH:            '/devsuite/static/auth',
    AUTH_LOGIN_ENDPOINT:          '',
    AUTH_LOGOUT_ENDPOINT:         '',
    AUTH_LOGOUT_EACH_ITERATION:   false,
    AUTH_STICKY_SESSIONS:         true,
    AUTH_DEBUG:                   false,
    AUTH_CONTEXT_API_PATH:        '/devsuite/web/api/context',
    AUTH_SESSION_DURATION_SECONDS: 0,

    DEBUG_CONFIG_OUTPUT:          false,

    ENABLE_FAILURE_DIAGNOSTICS:   true,
    FAILURE_LOG_LIMIT_PER_VU:     0,
    FAILURE_BODY_SNIPPET_LENGTH:  1024,

    API_PATH:                     '',
  },
  options: {
    setupTimeout:    '20m',
    teardownTimeout: '20m',
    tags:            { suite: 'oels' },
    thresholds:      {},
  }
});

// ---------------------------------------------------------------------------
// Allowed key sets - used for unknown-key rejection.
// ---------------------------------------------------------------------------

const VALID_TOP_LEVEL_KEYS  = new Set(['meta', 'run', 'env', 'options', 'scenarios', 'extends']);

// Pre-computed once at module load - SAFE_DEFAULTS is frozen and never changes.
const SAFE_DEFAULTS_JSON   = JSON.stringify(SAFE_DEFAULTS);
const VALID_META_KEYS      = new Set(['name', 'description', 'version']);
const VALID_RUN_KEYS       = new Set(['profile']);
const VALID_OPTIONS_KEYS   = new Set(['setupTimeout', 'teardownTimeout', 'tags', 'thresholds']);
const VALID_SCENARIOS_KEYS = new Set(['include', 'exclude']);
const VALID_PROFILES       = new Set(['smoke', 'simple', 'load', 'stress', 'chaos']);

const VALID_ENV_KEYS = new Set([
  'BASE_URL', 'API_PATH',
  'MAX_VUS', 'MAX_ITERATIONS', 'DURATION',
  'IDLE_STAGE_CHANCE', 'SCENARIO_STAGGER_SECONDS',
  'MIN_THINK_TIME', 'MAX_THINK_TIME',
  'CREATE_SEED_RECORDS', 'SEED_RECORD_MAX', 'SEED_RECORD_RATIO',
  'AUTH_REQUIRED', 'AUTH_USERNAME_PREFIX', 'AUTH_PASSWORD',
  'AUTH_CONTEXT_PATH', 'AUTH_LOGIN_ENDPOINT', 'AUTH_LOGOUT_ENDPOINT',
  'AUTH_LOGOUT_EACH_ITERATION', 'AUTH_STICKY_SESSIONS', 'AUTH_DEBUG',
  'AUTH_CONTEXT_API_PATH', 'AUTH_SESSION_DURATION_SECONDS',
  'DEBUG_CONFIG_OUTPUT',
  'ENABLE_FAILURE_DIAGNOSTICS', 'FAILURE_LOG_LIMIT_PER_VU', 'FAILURE_BODY_SNIPPET_LENGTH',
  'CRUD_WEIGHT', 'NOOP_WEIGHT', 'ANOMALY_SIMULATE_WEIGHT', 'ANOMALY_LEAK_WEIGHT', 'ANOMALY_DISRUPT_WEIGHT', 'ANOMALY_FILES_WEIGHT',
]);

// ---------------------------------------------------------------------------
// Validation helpers
// ---------------------------------------------------------------------------

/**
 * Returns a case-insensitive match from a Set, or undefined.
 * Used to generate "did you mean?" hints for typos in key names.
 * @param {Set<string>} validSet
 * @param {string} key
 * @returns {string|undefined}
 */
function findCaseInsensitiveMatch(validSet, key) {
  const lower = key.toLowerCase();
  for (const valid of validSet) {
    if (valid.toLowerCase() === lower) return valid;
  }
  return undefined;
}

/**
 * Returns a "did you mean?" hint string when the unknown key is a near-match.
 * Falls back to listing all valid keys when no match is found.
 * @param {Set<string>} validSet
 * @param {string} key
 * @returns {string}
 */
function unknownKeyHint(validSet, key) {
  const match = findCaseInsensitiveMatch(validSet, key);
  if (match) return ` Did you mean: "${match}"?`;
  return ` Valid keys: ${[...validSet].join(', ')}`;
}

const PROFILE_DESCRIPTIONS = {
  smoke:   'quick sanity check (1 VU, 1 iteration, strict quality gates)',
  simple:  'safe fallback (1 VU, 1 iteration, no quality gates)',
  load:    'steady-state load (MAX_VUS VUs, MAX_ITERATIONS total iterations)',
  stress:  'staircase ramp-up to MAX_VUS peak over DURATION minutes',
  chaos:   'randomized ramping-vus stages for DURATION minutes',
};

/**
 * Collects validation errors and throws a single descriptive Error at the end.
 * @param {object} cfg - Parsed (but not yet validated) config object.
 */
function validate(cfg) {
  const errors = [];

  // --- top-level keys ---
  for (const key of Object.keys(cfg)) {
    if (!VALID_TOP_LEVEL_KEYS.has(key)) {
      errors.push(`Unknown top-level key: "${key}".${unknownKeyHint(VALID_TOP_LEVEL_KEYS, key)}`);
    }
  }

  // --- required sections ---
  if (!cfg.meta)        errors.push('Missing required section: "meta"');
  if (!cfg.run)         errors.push('Missing required section: "run"');
  if (!cfg.env)         errors.push('Missing required section: "env"');

  if (errors.length) throw new Error(`[configLoader] Config validation failed:\n  - ${errors.join('\n  - ')}`);

  // --- meta keys ---
  for (const key of Object.keys(cfg.meta || {})) {
    if (!VALID_META_KEYS.has(key)) {
      errors.push(`Unknown meta key: "${key}".${unknownKeyHint(VALID_META_KEYS, key)}`);
    }
  }

  // --- run keys ---
  for (const key of Object.keys(cfg.run || {})) {
    if (!VALID_RUN_KEYS.has(key)) {
      errors.push(`Unknown run key: "${key}".${unknownKeyHint(VALID_RUN_KEYS, key)}`);
    }
  }

  // --- profile ---
  if (cfg.run && cfg.run.profile !== undefined) {
    const profileStr = String(cfg.run.profile).toLowerCase();
    if (!VALID_PROFILES.has(profileStr)) {
      const profileList = Object.entries(PROFILE_DESCRIPTIONS)
        .map(([k, v]) => `    ${k} - ${v}`)
        .join('\n');
      errors.push(
        `Invalid run.profile: "${cfg.run.profile}". Valid profiles:\n${profileList}`
      );
    }
  }

  // --- env keys ---
  for (const key of Object.keys(cfg.env || {})) {
    if (!VALID_ENV_KEYS.has(key)) {
      errors.push(`Unknown env key: "${key}".${unknownKeyHint(VALID_ENV_KEYS, key)}`);
    }
  }

  const env = cfg.env || {};

  // --- type checks ---
  const BOOL_FIELDS = [
    'AUTH_REQUIRED', 'AUTH_LOGOUT_EACH_ITERATION', 'AUTH_STICKY_SESSIONS',
    'AUTH_DEBUG', 'DEBUG_CONFIG_OUTPUT', 'ENABLE_FAILURE_DIAGNOSTICS',
  ];
  for (const field of BOOL_FIELDS) {
    if (env[field] !== undefined && typeof env[field] !== 'boolean') {
      errors.push(
        `env.${field} must be a JSON boolean (true or false); ` +
        `got ${typeof env[field]}: ${JSON.stringify(env[field])}. ` +
        `Remove the quotes if you passed a string.`
      );
    }
  }

  const STRING_FIELDS = [
    'BASE_URL', 'API_PATH', 'AUTH_USERNAME_PREFIX', 'AUTH_PASSWORD',
    'AUTH_CONTEXT_PATH', 'AUTH_LOGIN_ENDPOINT', 'AUTH_LOGOUT_ENDPOINT'
  ];
  for (const field of STRING_FIELDS) {
    if (env[field] !== undefined && typeof env[field] !== 'string') {
      errors.push(
        `env.${field} must be a JSON string; ` +
        `got ${typeof env[field]}: ${JSON.stringify(env[field])}`
      );
    }
  }

  if (env.BASE_URL !== undefined && typeof env.BASE_URL === 'string' && env.BASE_URL.trim() === '') {
    errors.push('env.BASE_URL must be a non-empty string. Example: "http://host:7780"');
  }

  // --- numeric range checks ---
  function checkInt(field, min, max, hint) {
    if (env[field] === undefined) return;
    if (typeof env[field] !== 'number') {
      errors.push(
        `env.${field} must be a JSON number; ` +
        `got ${typeof env[field]}: ${JSON.stringify(env[field])}. Remove the quotes if you passed a string.`
      );
      return;
    }
    const n = Math.trunc(env[field]);
    if (n !== env[field]) {
      errors.push(`env.${field} must be an integer; got: ${env[field]}`);
    } else if (n < min) {
      errors.push(`env.${field} must be >= ${min}; got: ${n}${hint ? `. ${hint}` : ''}`);
    } else if (max !== undefined && n > max) {
      errors.push(`env.${field} must be <= ${max}; got: ${n}`);
    }
  }

  function checkFloat(field, min, max) {
    if (env[field] === undefined) return;
    if (typeof env[field] !== 'number') {
      errors.push(
        `env.${field} must be a JSON number; ` +
        `got ${typeof env[field]}: ${JSON.stringify(env[field])}. Remove the quotes if you passed a string.`
      );
      return;
    }
    if (!Number.isFinite(env[field])) {
      errors.push(`env.${field} must be a finite number; got: ${env[field]}`);
    } else if (env[field] < min) {
      errors.push(`env.${field} must be >= ${min}; got: ${env[field]}`);
    } else if (max !== undefined && env[field] > max) {
      errors.push(`env.${field} must be <= ${max}; got: ${env[field]}`);
    }
  }

  checkInt  ('MAX_VUS',                     2,  undefined, 'Smoke/simple profiles use 1 VU at runtime, but MAX_VUS must still be >= 2');
  checkInt  ('MAX_ITERATIONS',              1);
  checkInt  ('DURATION',                    5,  undefined, 'Minimum 5 minutes; use DURATION >= 10 for meaningful load runs');
  checkFloat('IDLE_STAGE_CHANCE',           0,  1);
  checkFloat('SCENARIO_STAGGER_SECONDS',    0);
  checkFloat('MIN_THINK_TIME',              0);
  checkFloat('MAX_THINK_TIME',              0);
  checkInt  ('SEED_RECORD_RATIO',           1);
  checkInt  ('FAILURE_LOG_LIMIT_PER_VU',    0,  undefined, '0 means unlimited; set a positive cap for high-VU runs');
  checkInt  ('FAILURE_BODY_SNIPPET_LENGTH', 80, undefined, 'Minimum 80 chars to ensure useful snippets');
  checkFloat('CRUD_WEIGHT',                 0,  1);
  checkFloat('NOOP_WEIGHT',                 0,  1);
  checkFloat('ANOMALY_DISRUPT_WEIGHT',      0,  1);
  checkFloat('ANOMALY_FILES_WEIGHT',        0,  1);
  checkFloat('ANOMALY_LEAK_WEIGHT',         0,  1);
  checkFloat('ANOMALY_SIMULATE_WEIGHT',     0,  1);

  // --- cross-field checks ---
  // The weighted random selection algorithm in pickWeightedOperation() (launchUnifiedScenario.js)
  // requires all six weights to sum to 1.0 so each weight accurately represents its percentage
  // share of the total workload. Enforce that here when any weight is explicitly configured.
  const anyWeightDefined = env.CRUD_WEIGHT !== undefined || env.NOOP_WEIGHT !== undefined ||
    env.ANOMALY_SIMULATE_WEIGHT !== undefined || env.ANOMALY_LEAK_WEIGHT !== undefined ||
    env.ANOMALY_DISRUPT_WEIGHT !== undefined || env.ANOMALY_FILES_WEIGHT !== undefined;
  if (anyWeightDefined) {
    const cw  = typeof env.CRUD_WEIGHT             === 'number' ? env.CRUD_WEIGHT             : 0.9;
    const nw  = typeof env.NOOP_WEIGHT             === 'number' ? env.NOOP_WEIGHT             : 0.1;
    const adw = typeof env.ANOMALY_DISRUPT_WEIGHT  === 'number' ? env.ANOMALY_DISRUPT_WEIGHT  : 0.0;
    const afw = typeof env.ANOMALY_FILES_WEIGHT    === 'number' ? env.ANOMALY_FILES_WEIGHT    : 0.0;
    const alw = typeof env.ANOMALY_LEAK_WEIGHT     === 'number' ? env.ANOMALY_LEAK_WEIGHT     : 0.0;
    const asw = typeof env.ANOMALY_SIMULATE_WEIGHT === 'number' ? env.ANOMALY_SIMULATE_WEIGHT : 0.0;
    if (Math.abs(cw + nw + asw + alw + adw + afw - 1.0) > 0.001) {
      errors.push(
        `env.CRUD_WEIGHT (${cw}) + env.NOOP_WEIGHT (${nw}) + env.ANOMALY_SIMULATE_WEIGHT (${asw}) + ` +
        `env.ANOMALY_LEAK_WEIGHT (${alw}) + env.ANOMALY_DISRUPT_WEIGHT (${adw}) + env.ANOMALY_FILES_WEIGHT (${afw}) must sum to 1.0; ` +
        `got: ${(cw + nw + asw + alw + adw + afw).toFixed(4)}. Adjust the weights so they total exactly 1.0.`
      );
    }
  }

  if (typeof env.MIN_THINK_TIME === 'number' && typeof env.MAX_THINK_TIME === 'number') {
    if (Number.isFinite(env.MIN_THINK_TIME) && Number.isFinite(env.MAX_THINK_TIME)
        && env.MAX_THINK_TIME < env.MIN_THINK_TIME) {
      errors.push(
        `env.MAX_THINK_TIME (${env.MAX_THINK_TIME}) must be >= env.MIN_THINK_TIME (${env.MIN_THINK_TIME}). ` +
        `For fixed think time, set both to the same value.`
      );
    }
  }

  // --- options keys ---
  for (const key of Object.keys(cfg.options || {})) {
    if (!VALID_OPTIONS_KEYS.has(key)) {
      errors.push(`Unknown options key: "${key}".${unknownKeyHint(VALID_OPTIONS_KEYS, key)}`);
    }
  }

  // --- options.thresholds shape ---
  if (cfg.options?.thresholds !== undefined) {
    if (typeof cfg.options.thresholds !== 'object' || cfg.options.thresholds === null || Array.isArray(cfg.options.thresholds)) {
      errors.push('options.thresholds must be a JSON object mapping metric names to string-array expressions.');
    } else {
      for (const [metricName, expressions] of Object.entries(cfg.options.thresholds)) {
        if (!Array.isArray(expressions)) {
          errors.push(`options.thresholds.${metricName} must be an array of string expressions.`);
          continue;
        }
        if (expressions.length === 0) {
          errors.push(`options.thresholds.${metricName} must contain at least one expression.`);
          continue;
        }
        const nonStringExpr = expressions.find((expr) => typeof expr !== 'string');
        if (nonStringExpr !== undefined) {
          errors.push(`options.thresholds.${metricName} expressions must be strings. Invalid value: ${JSON.stringify(nonStringExpr)}`);
        }
      }
    }
  }

  // --- scenarios keys ---
  for (const key of Object.keys(cfg.scenarios || {})) {
    if (!VALID_SCENARIOS_KEYS.has(key)) {
      errors.push(`Unknown scenarios key: "${key}".${unknownKeyHint(VALID_SCENARIOS_KEYS, key)}`);
    }
  }

  if (errors.length) {
    throw new Error(`[configLoader] Config validation failed:\n  - ${errors.join('\n  - ')}`);
  }
}

/**
 * Deep-merges source into target. Arrays replace (no concat).
 * @param {object} target
 * @param {object} source
 * @returns {object} Merged object (mutates target).
 */
function deepMerge(target, source) {
  for (const key of Object.keys(source)) {
    if (source[key] !== null && typeof source[key] === 'object' && !Array.isArray(source[key])
        && target[key] !== null && typeof target[key] === 'object' && !Array.isArray(target[key])) {
      deepMerge(target[key], source[key]);
    } else {
      target[key] = source[key];
    }
  }
  return target;
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Loads, validates, and returns a fully-resolved config object.
 *
 * When rawJson is null / undefined (no CONFIG_FILE set), prints a visible warning
 * and returns the safe smoke defaults. No --env overrides are applied.
 *
 * When rawJson is provided, parses the JSON, validates structure and value ranges,
 * then merges in order: SAFE_DEFAULTS ← base config (extends) ← current config.
 * Current config values always win.
 *
 * Throws an Error with an actionable message if validation fails. k6 will surface
 * this as an init-context failure and abort before any VU or setup phase starts.
 *
 * @param {string|null} rawJson     - Raw JSON string from open(__ENV.CONFIG_FILE), or null.
 * @param {string|null} baseRawJson - Raw JSON string from open(parsed.extends), or null.
 * @returns {object} Fully-resolved config matching the SAFE_DEFAULTS shape.
 */
export function loadConfig(rawJson, baseRawJson) {
  if (!rawJson) {
    console.warn(
      '[config] No CONFIG_FILE provided - running smoke defaults (1 VU, 1 iteration).\n' +
      '         To run a real test: k6 run --env CONFIG_FILE=configs/<config_name>.json <launcher>.js'
    );
    return JSON.parse(SAFE_DEFAULTS_JSON); // deep clone
  }

  let parsed;
  try {
    parsed = JSON.parse(rawJson);
  } catch (e) {
    throw new Error(`[configLoader] Failed to parse CONFIG_FILE as JSON: ${e.message}`);
  }

  if (typeof parsed !== 'object' || Array.isArray(parsed) || parsed === null) {
    throw new Error('[configLoader] CONFIG_FILE must be a JSON object at the top level.');
  }

  validate(parsed);

  // Merge: SAFE_DEFAULTS ← base config (extends) ← current config. Current wins.
  const resolved = JSON.parse(SAFE_DEFAULTS_JSON);

  if (baseRawJson) {
    let baseParsed;
    try {
      baseParsed = JSON.parse(baseRawJson);
    } catch (e) {
      throw new Error(`[configLoader] Failed to parse extends base config as JSON: ${e.message}`);
    }
    if (typeof baseParsed !== 'object' || Array.isArray(baseParsed) || baseParsed === null) {
      throw new Error('[configLoader] extends base config must be a JSON object at the top level.');
    }
    validate(baseParsed);
    deepMerge(resolved, baseParsed);
  }

  deepMerge(resolved, parsed);

  // Auto-derive options.tags.config from meta.name unless explicitly set in the config.
  if (!resolved.options.tags.config) {
    resolved.options.tags.config = resolved.meta.name;
  }

  // Normalize profile to lowercase.
  resolved.run.profile = resolved.run.profile.toLowerCase();

  // Resolve empty AUTH endpoint strings to derived defaults from AUTH_CONTEXT_PATH.
  const ctxPath = resolved.env.AUTH_CONTEXT_PATH;
  if (!resolved.env.AUTH_LOGIN_ENDPOINT) {
    resolved.env.AUTH_LOGIN_ENDPOINT = `${ctxPath}/j_spring_security_check`;
  }
  if (!resolved.env.AUTH_LOGOUT_ENDPOINT) {
    resolved.env.AUTH_LOGOUT_ENDPOINT = `${ctxPath}/j_spring_security_logout`;
  }

  return resolved;
}

/**
 * Logs the fully-resolved config and effective k6 options to the console.
 * Prints only from __VU === 0 (the init context proto-VU) so it appears once.
 * AUTH_PASSWORD is masked with '***' to avoid leaking credentials in output.
 *
 * @param {object} cfg              - Resolved config from loadConfig().
 * @param {object} effectiveOptions - The computed k6 options object.
 */
export function logResolvedConfig(cfg, effectiveOptions) {
  if (!cfg?.env?.DEBUG_CONFIG_OUTPUT) return;
  const displayEnv = Object.assign({}, cfg.env);
  if (displayEnv.AUTH_PASSWORD) displayEnv.AUTH_PASSWORD = '***';
  console.log(
    '[config] Resolved Configuration:\n' +
    JSON.stringify({ meta: cfg.meta, run: cfg.run, env: displayEnv, effectiveOptions }, null, 2)
  );
}
