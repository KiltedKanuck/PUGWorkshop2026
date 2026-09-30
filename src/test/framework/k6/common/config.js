/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 */

/**
 * Default server URL for API endpoints.
 * Can be overridden via --env BASE_URL when running k6.
 * NOTE: The default server/port is set to a common test environment in AWS.
 */
export const DEFAULT_SERVER_URL = 'http://127.0.0.1:7780';

/**
 * Standard API prefix for all load suite test endpoints.
 */
export const API_PREFIX = '/loadsuite/web/api';


/**
 * Standard API prefix for all system-monitoring endpoints.
 */
export const MONITOR_PREFIX = '/monitor/web/api';

/**
 * Data service paths for various operations.
 */
export const ANOMALY_SERVICE = '/anomaly';
export const DATA_SERVICE = '/data';
export const OBJECTS_SERVICE = '/objects';
export const PROCEDURES_SERVICE = '/procedures';
export const SYSTEM_SERVICE = '/system';

/**
 * Default profile used when PROFILE is not provided via --env.
 */
export const DEFAULT_PROFILE = 'simple';

/**
 * =============================
 * Runtime-Evaluated Constants
 * =============================
 * These values are resolved in init context using --env overrides when present.
 */

/**
 * Base URL for requests with optional --env BASE_URL override.
 * Use setBaseUrl() to override from a config file.
 */
export let BASE_URL = __ENV.BASE_URL || DEFAULT_SERVER_URL;

/**
 * @param {string} v - New base URL.
 */
export function setBaseUrl(v) {
  if (v && typeof v === 'string') {
    BASE_URL = v.replace(/\/+$/, ''); // strip trailing slashes
  }
}

/**
 * Active test profile with optional --env PROFILE=<profile_name> override.
 * Use getProfile() and setProfile() to access/modify the active profile.
 */
let _activeProfile = (__ENV.PROFILE || DEFAULT_PROFILE).toLowerCase();

/**
 * Get the currently active test profile.
 * @returns {string} Current profile name (smoke, load, stress, chaos, or simple).
 */
export function getProfile() {
  return _activeProfile;
}

/**
 * Override the active test profile at runtime.
 * Useful for launchers that need to set a default profile before modules initialize.
 * @param {string} profile - New profile name.
 */
export function setProfile(profile) {
  _activeProfile = (profile || DEFAULT_PROFILE).toLowerCase();
}

/**
 * Execution duration with optional --env DURATION=<duration_in_minutes> override.
 * Use setDuration() to override from a config file.
 */
export let DURATION = Math.max(5, parseInt(__ENV.DURATION, 10) || 10);

/**
 * @param {number|string} v - New duration in minutes (minimum 5).
 */
export function setDuration(v) {
  const n = parseInt(v, 10);
  DURATION = Number.isFinite(n) ? Math.max(5, n) : 10;
}

/**
 * Maximum concurrent Virtual Users for all profiles.
 * Use setMaxVus() to override from a config file.
 */
export let MAX_VUS = Math.max(2, parseInt(__ENV.MAX_VUS, 10) || 20);

/**
 * @param {number|string} v - New VU ceiling (minimum 2).
 */
export function setMaxVus(v) {
  const n = parseInt(v, 10);
  MAX_VUS = Number.isFinite(n) ? Math.max(2, n) : 20;
}

/**
 * Maximum iterations for shared-iterations profiles (smoke, simple, load).
 * Use setMaxIterations() to override from a config file.
 */
export let MAX_ITERATIONS = Math.max(1, parseInt(__ENV.MAX_ITERATIONS, 10) || 100);

/**
 * @param {number|string} v - New iteration ceiling (minimum 1).
 */
export function setMaxIterations(v) {
  const n = parseInt(v, 10);
  MAX_ITERATIONS = Number.isFinite(n) ? Math.max(1, n) : 100;
}

/**
 * Simulate idle periods in chaos scenarios.
 * Use setIdleStageChance() to override from a config file.
 */
export let IDLE_STAGE_CHANCE = Math.max(0, parseFloat(__ENV.IDLE_STAGE_CHANCE) || 0.05);

/**
 * @param {number|string} v - New idle stage probability (0–1 inclusive).
 */
export function setIdleStageChance(v) {
  const n = parseFloat(v);
  IDLE_STAGE_CHANCE = Number.isFinite(n) ? Math.min(1, Math.max(0, n)) : 0.05;
}

/**
 * Seconds between each scenario's startTime in multi-scenario launchers.
 * Use setScenarioStaggerSeconds() to override from a config file.
 */
export let SCENARIO_STAGGER_SECONDS = Math.max(0, parseFloat(__ENV.SCENARIO_STAGGER_SECONDS) || 0.5);

/**
 * @param {number|string} v - New stagger gap in seconds (minimum 0).
 */
export function setScenarioStaggerSeconds(v) {
  const n = parseFloat(v);
  SCENARIO_STAGGER_SECONDS = Number.isFinite(n) ? Math.max(0, n) : 0.5;
}

/**
 * Minimum think time in seconds.
 * Use setMinThinkTime() to override from a config file.
 */
export let MIN_THINK_TIME = Math.max(0, parseFloat(__ENV.MIN_THINK_TIME) || 0.1);

/**
 * @param {number|string} v - New minimum think time in seconds (minimum 0).
 */
export function setMinThinkTime(v) {
  const n = parseFloat(v);
  MIN_THINK_TIME = Number.isFinite(n) ? Math.max(0, n) : 0.1;
}

/**
 * Maximum think time in seconds used only by the chaos profile.
 * Use setMaxThinkTime() to override from a config file.
 */
export let MAX_THINK_TIME = Math.max(0, parseFloat(__ENV.MAX_THINK_TIME) || 1.0);

/**
 * @param {number|string} v - New maximum think time in seconds (minimum 0).
 */
export function setMaxThinkTime(v) {
  const n = parseFloat(v);
  MAX_THINK_TIME = Number.isFinite(n) ? Math.max(0, n) : 1.0;
}

/**
 * Maximum number of pre-existing seed records available in the database pool.
 * Used when CREATE_SEED_RECORDS is false to bound the random record selection range.
 * Use setSeedRecordMax() to override from a config file.
 */
export let SEED_RECORD_MAX = Math.max(1, parseInt(__ENV.SEED_RECORD_MAX, 10) || 100000);

/**
 * @param {number|string} v - New seed record pool size (minimum 1).
 */
export function setSeedRecordMax(v) {
  const n = Math.trunc(parseInt(v, 10));
  SEED_RECORD_MAX = Number.isFinite(n) && n >= 1 ? n : 100000;
}

/**
 * Relative weight for CRUD operations in the unified scenario dispatch table.
 * Combined with NOOP_WEIGHT, ANOMALY_SIMULATE_WEIGHT, ANOMALY_LEAK_WEIGHT, ANOMALY_DISRUPT_WEIGHT,
 * and ANOMALY_FILES_WEIGHT; all six weights must sum to 1.0.
 * The 1.0 sum is required by the weighted random selection algorithm in pickWeightedOperation()
 * (launchUnifiedScenario.js): the algorithm scales a random value against the total weight, so
 * the total determines the full selection range. If the weights do not sum to 1.0, the algorithm
 * still works proportionally, but the intent of each weight as a percentage is no longer accurate.
 * Use setCrudWeight() to override from a config file.
 */
export let CRUD_WEIGHT = Math.min(1, Math.max(0, parseFloat(__ENV.CRUD_WEIGHT) || 0.90));

/**
 * @param {number|string} v - New CRUD weight (0–1 inclusive).
 */
export function setCrudWeight(v) {
  const n = parseFloat(v);
  CRUD_WEIGHT = Number.isFinite(n) ? Math.min(1, Math.max(0, n)) : 0.90;
}

/**
 * Relative weight for NOOP (objects service) operations in the unified scenario dispatch table.
 * Combined with CRUD_WEIGHT, ANOMALY_SIMULATE_WEIGHT, ANOMALY_LEAK_WEIGHT, ANOMALY_DISRUPT_WEIGHT,
 * and ANOMALY_FILES_WEIGHT; all six weights must sum to 1.0.
 * Use setNoopWeight() to override from a config file.
 */
export let NOOP_WEIGHT = Math.min(1, Math.max(0, parseFloat(__ENV.NOOP_WEIGHT) || 0.10));

/**
 * @param {number|string} v - New NOOP weight (0–1 inclusive).
 */
export function setNoopWeight(v) {
  const n = parseFloat(v);
  NOOP_WEIGHT = Number.isFinite(n) ? Math.min(1, Math.max(0, n)) : 0.10;
}

/**
 * Relative weight for simulate anomalies (e.g. codeBusy) in the unified scenario dispatch table.
 * Defaults to 0.0 (disabled). Combined with CRUD_WEIGHT, NOOP_WEIGHT, ANOMALY_LEAK_WEIGHT,
 * ANOMALY_DISRUPT_WEIGHT, and ANOMALY_FILES_WEIGHT; all six weights must sum to 1.0.
 * Use setAnomalySimulateWeight() to override from a config file.
 */
export let ANOMALY_SIMULATE_WEIGHT = Math.min(1, Math.max(0, parseFloat(__ENV.ANOMALY_SIMULATE_WEIGHT) || 0.00));

/**
 * @param {number|string} v - New anomaly simulate weight (0–1 inclusive).
 */
export function setAnomalySimulateWeight(v) {
  const n = parseFloat(v);
  ANOMALY_SIMULATE_WEIGHT = Number.isFinite(n) ? Math.min(1, Math.max(0, n)) : 0.00;
}

/**
 * Relative weight for leak anomalies (leakBuffer, leakHandle, leakMemptr, leakObject)
 * in the unified scenario dispatch table. Defaults to 0.0 (disabled).
 * Combined with CRUD_WEIGHT, NOOP_WEIGHT, ANOMALY_SIMULATE_WEIGHT, ANOMALY_DISRUPT_WEIGHT,
 * and ANOMALY_FILES_WEIGHT; all six weights must sum to 1.0.
 * Use setAnomalyLeakWeight() to override from a config file.
 */
export let ANOMALY_LEAK_WEIGHT = Math.min(1, Math.max(0, parseFloat(__ENV.ANOMALY_LEAK_WEIGHT) || 0.00));

/**
 * @param {number|string} v - New anomaly leak weight (0–1 inclusive).
 */
export function setAnomalyLeakWeight(v) {
  const n = parseFloat(v);
  ANOMALY_LEAK_WEIGHT = Number.isFinite(n) ? Math.min(1, Math.max(0, n)) : 0.00;
}

/**
 * Relative weight for disrupt anomalies (dbDisconnect, codeQuit, codeStop)
 * in the unified scenario dispatch table. Defaults to 0.0 (disabled).
 * WARNING: enabling this weight includes codeQuit (HTTP 500) and codeStop (HTTP 408),
 * which return non-2xx by design. Remove the checks threshold from your config when
 * using ANOMALY_DISRUPT_WEIGHT > 0, or check failures will be reported.
 * Combined with CRUD_WEIGHT, NOOP_WEIGHT, ANOMALY_SIMULATE_WEIGHT, ANOMALY_LEAK_WEIGHT,
 * and ANOMALY_FILES_WEIGHT; all six weights must sum to 1.0.
 * Use setAnomalyDisruptWeight() to override from a config file.
 */
export let ANOMALY_DISRUPT_WEIGHT = Math.min(1, Math.max(0, parseFloat(__ENV.ANOMALY_DISRUPT_WEIGHT) || 0.00));

/**
 * @param {number|string} v - New anomaly disrupt weight (0–1 inclusive).
 */
export function setAnomalyDisruptWeight(v) {
  const n = parseFloat(v);
  ANOMALY_DISRUPT_WEIGHT = Number.isFinite(n) ? Math.min(1, Math.max(0, n)) : 0.00;
}

/**
 * Relative weight for files anomalies (osCommandData, inputThroughData)
 * in the unified scenario dispatch table. Defaults to 0.0 (disabled).
 * These operations fork the session agent process, temporarily copying its virtual address space,
 * making them useful for measuring OS-level memory impact.
 * Combined with CRUD_WEIGHT, NOOP_WEIGHT, ANOMALY_SIMULATE_WEIGHT, ANOMALY_LEAK_WEIGHT,
 * and ANOMALY_DISRUPT_WEIGHT; all six weights must sum to 1.0.
 * Use setAnomalyFilesWeight() to override from a config file.
 */
export let ANOMALY_FILES_WEIGHT = Math.min(1, Math.max(0, parseFloat(__ENV.ANOMALY_FILES_WEIGHT) || 0.00));

/**
 * @param {number|string} v - New anomaly files weight (0–1 inclusive).
 */
export function setAnomalyFilesWeight(v) {
  const n = parseFloat(v);
  ANOMALY_FILES_WEIGHT = Number.isFinite(n) ? Math.min(1, Math.max(0, n)) : 0.00;
}

/**
 * Applies all env-section values from a resolved config object to this module's
 * runtime constants. Call this before buildScenarioFromProfile() in launcher init context.
 * @param {object} env - The resolved config.env object from configLoader.loadConfig().
 */
export function applyEnvConfig(env) {
  if (!env) return;
  if (env.BASE_URL           !== undefined) setBaseUrl(env.BASE_URL);
  if (env.DURATION           !== undefined) setDuration(env.DURATION);
  if (env.MAX_VUS            !== undefined) setMaxVus(env.MAX_VUS);
  if (env.MAX_ITERATIONS     !== undefined) setMaxIterations(env.MAX_ITERATIONS);
  if (env.IDLE_STAGE_CHANCE  !== undefined) setIdleStageChance(env.IDLE_STAGE_CHANCE);
  if (env.SCENARIO_STAGGER_SECONDS !== undefined) setScenarioStaggerSeconds(env.SCENARIO_STAGGER_SECONDS);
  if (env.MIN_THINK_TIME     !== undefined) setMinThinkTime(env.MIN_THINK_TIME);
  if (env.MAX_THINK_TIME     !== undefined) setMaxThinkTime(env.MAX_THINK_TIME);
  if (env.SEED_RECORD_MAX    !== undefined) setSeedRecordMax(env.SEED_RECORD_MAX);
  if (env.CRUD_WEIGHT             !== undefined) setCrudWeight(env.CRUD_WEIGHT);
  if (env.NOOP_WEIGHT             !== undefined) setNoopWeight(env.NOOP_WEIGHT);
  if (env.ANOMALY_DISRUPT_WEIGHT  !== undefined) setAnomalyDisruptWeight(env.ANOMALY_DISRUPT_WEIGHT);
  if (env.ANOMALY_FILES_WEIGHT    !== undefined) setAnomalyFilesWeight(env.ANOMALY_FILES_WEIGHT);
  if (env.ANOMALY_LEAK_WEIGHT     !== undefined) setAnomalyLeakWeight(env.ANOMALY_LEAK_WEIGHT);
  if (env.ANOMALY_SIMULATE_WEIGHT !== undefined) setAnomalySimulateWeight(env.ANOMALY_SIMULATE_WEIGHT);
}
