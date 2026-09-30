/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 */

import {
  getProfile,
  DURATION,
  IDLE_STAGE_CHANCE,
  MAX_VUS,
  MAX_ITERATIONS,
  SCENARIO_STAGGER_SECONDS,
} from './config.js';
import { AUTH_STICKY_SESSIONS } from './auth.js';

/**
 * Merges default profile thresholds with optional config overrides.
 * Override keys replace only the targeted metric while preserving the rest.
 * @param {object} defaults - Built-in thresholds for the selected profile.
 * @param {object} [overrides] - Optional overrides from config.options.thresholds.
 * @returns {object} Effective threshold map.
 */
function mergeThresholds(defaults, overrides) {
  if (!overrides || typeof overrides !== 'object') {
    return defaults;
  }
  return {
    ...defaults,
    ...overrides,
  };
}

export function buildTopLevelProfileOptions() {
  return {
    noCookiesReset: AUTH_STICKY_SESSIONS,
    // `systemTags` is a standard k6 option.
    // This list acts as an explicit whitelist of built-in tags to include,
    // overriding k6 defaults. We intentionally omit `url` so full request URLs
    // (including query parameters) are not attached to metrics, which prevents
    // high-cardinality time-series growth from dynamic query values.
    systemTags: [
      'proto',
      'subproto',
      'status',
      'method',
      'name',
      'group',
      'check',
      'error',
      'error_code',
      'tls_version',
      'scenario',
      'service',
      'expected_response',
    ],
  };
}

/**
 * Builds a k6 scenario configuration object from a profile name.
 *
 * Each profile returns load-shaping fields that tell k6 how to run traffic.
 * These parameters are shared by individual test scripts so behavior stays
 * consistent across the suite.
 *
 * Profiles:
 * - `simple` (default): same execution shape as smoke with default thresholds.
 * - `smoke`: minimal quick check (1 VU, 1 iteration), strict quality gates.
 * - `load`: steady load (MAX_VUS VUs, MAX_ITERATIONS total iterations).
 * - `stress`: escalating load over time using `stages`, with peak at MAX_VUS.
 * - `chaos`: randomized ramping stages for `DURATION` minutes, max stage target is MAX_VUS.
 *
 * @param {object} [thresholdOverrides] - Optional k6 threshold map merged on top
 *   of the selected profile defaults.
 * @returns {object} k6 scenario options for the selected profile.
 */
export function buildScenarioFromProfile(thresholdOverrides) {
  const profile = getProfile(); // Get the active test profile.
  if (profile === 'smoke') {
    /**
     * Smoke profile (quick correctness gate):
     * - Execution model: shared-iterations (derived from vus + iterations)
     * - Load shape: 1 virtual user performs 1 total iteration
     * - Quality gates: strict (0 failed HTTP requests, all checks must pass)
     * - Typical use: pre-commit sanity check / pipeline health signal
     */
    return {
      ...buildTopLevelProfileOptions(),
      iterations: 1, // just a single iteration to verify basic functionality
      vus: 1, // single user to execute the single iteration
      thresholds: mergeThresholds({
        http_req_failed:   ['rate==0'], // no failed requests allowed
        http_req_duration: ['p(90)<1000', 'p(95)<1200', 'p(99)<1800'], // tighter quick-check latency gates for single-VU smoke runs
        checks:            ['rate==1'], // all checks must pass (100% success rate)
      }, thresholdOverrides),
      tags: {
        profile: 'smoke',
      },
    };
  }

  if (profile === 'load') {
    /**
     * Load profile (baseline throughput run w/ consistency):
     * - Execution model: shared-iterations
     * - Load shape: MAX_VUS concurrent VUs, MAX_ITERATIONS total iterations
     * - Quality gates: moderate (small failure budget + latency target)
     * - Typical use: compare current behavior to expected steady-state performance
     */
    return {
      ...buildTopLevelProfileOptions(),
      iterations: MAX_ITERATIONS, // total work items to execute across all VUs
      vus: MAX_VUS, // number of virtual users to run in parallel to execute the iterations
      thresholds: mergeThresholds({
        http_req_failed:   ['rate<0.01'], // allow up to 1% failed requests
        http_req_duration: ['p(90)<8000', 'p(95)<9500', 'p(99)<12000'], // multiple guards for median/tail latency
      }, thresholdOverrides),
      tags: {
        profile: 'load',
        params: `${MAX_ITERATIONS} iters / ${MAX_VUS} vus`,
      },
    };
  }

  if (profile === 'stress') {
    /**
     * Stress profile (stability under increasing pressure):
     * - Execution model: ramping-vus (derived from stages)
     * - Load shape: staircase ramp-up to MAX_VUS peak, then cooldown
     * - Quality gates: looser than smoke/load to allow stress-induced variance
     * - Typical use: identify saturation points and degradation behavior
     *
     * Stage durations scale based on DURATION:
     * - Four active stages (warmup, ramp 1, ramp 2, peak) each get DURATION/5 minutes
     * - Cooldown ramp gets the remainder time, at least 1 minute
     * - Ensures predictable total test duration matching --env DURATION
     *
     * VU targets scale dynamically based on MAX_VUS:
     * - Ramp to 1/4 of MAX_VUS
     * - Ramp to 1/2 of MAX_VUS
     * - Ramp to 3/4 of MAX_VUS
     * - Ramp to MAX_VUS (peak)
     * - Cooldown to 0 VUs
     */
    const warmup = Math.max(1, Math.floor(MAX_VUS * 0.25));
    const step1 = Math.max(1, Math.floor(MAX_VUS * 0.5));
    const step2 = Math.max(1, Math.floor(MAX_VUS * 0.75));

    const stageDurationMins = Math.max(1, Math.floor(DURATION / 5)); // Base for active stages, ensuring at least 1 minute each
    const cooldownMins = DURATION - (4 * stageDurationMins); // Remainder for cooldown, ensuring total duration matches DURATION
    const stageDuration = `${stageDurationMins}m`;
    const cooldownDuration = `${cooldownMins}m`;

    return {
      ...buildTopLevelProfileOptions(),
      stages: [
        { duration: stageDuration, target: warmup },  // warm-up: bring traffic online to ~1/4 VUs
        { duration: stageDuration, target: step1 },   // ramp step 1: increase to moderate concurrency
        { duration: stageDuration, target: step2 },   // ramp step 2: increase to sustained higher load
        { duration: stageDuration, target: MAX_VUS }, // peak load: push toward expected stress limit
        { duration: cooldownDuration, target: 0 },    // cooldown: ramp down traffic to zero VUs
      ],
      thresholds: mergeThresholds({
        http_req_failed:   ['rate<0.01'], // allow up to 1% failed requests under heavy load
        http_req_duration: ['p(90)<8000', 'p(95)<9500', 'p(99)<12000'], // multiple guards for median/tail latency
      }, thresholdOverrides),
      tags: {
        profile: 'stress',
        params: `${DURATION} mins / ${MAX_VUS} vus`,
      },
    };
  }

  if (profile === 'chaos') {
    /**
     * Chaos profile (volatile and unpredictable traffic):
     * - Execution model: stage-driven top-level options (single-test scripts)
     * - Load shape: minute-by-minute randomized targets for DURATION minutes
     * - Quality gates: intentionally not set here; caller chooses enforcement scope
     * - Typical use: resilience testing against spiky/irregular concurrency patterns
     */
    return {
      ...buildTopLevelProfileOptions(),
      stages: generateRandomStages(DURATION), // chaotic load for specified duration
      thresholds: mergeThresholds({
        'http_req_failed{profile:chaos}':   ['rate<0.05'],  // allow up to 5% failed requests under heavy load
        'checks{profile:chaos}':            ['rate>=0.95'], // expect at least 95% successful checks under heavy load
        'http_req_duration{profile:chaos}': ['p(90)<8000', 'p(95)<9500', 'p(99)<12000'], // multiple guards for median/tail latency
      }, thresholdOverrides),
      tags: {
        profile: 'chaos',
        params: `${DURATION} mins / ${MAX_VUS} vus`,
      },
    }
  }

  /**
   * Default/simple profile (safe fallback):
   * - Applied when the profile is omitted or unrecognized
   * - Uses conservative shared-iterations shape similar to smoke
   * - Keeps baseline thresholds so accidental profile omissions still run safely
   */
  return {
    ...buildTopLevelProfileOptions(),
    iterations: 1, // just a single iteration to verify basic functionality
    vus: 1, // single user to execute the single iteration
    thresholds: mergeThresholds({
      http_req_failed:   ['rate==0'], // no failed requests allowed
      http_req_duration: ['p(90)<1000', 'p(95)<1200', 'p(99)<1800'], // tighter quick-check latency gates for single-VU simple runs
    }, thresholdOverrides),
    tags: {
      profile: 'simple',
    },
  };
}

/**
 * Builds per-scenario execution fields for multi-scenario launcher files.
 *
 * Input source:
 * - Reads the selected profile from `buildScenarioFromProfile()`.
 *
 * Output intent:
 * - Returns scenario-level scheduling fields that can be spread into each
 *   `options.scenarios.<scenarioName>` entry.
 * - Excludes profile `thresholds`; launcher files keep thresholds in one
 *   top-level `options.thresholds` block.
 *
 * Returned scheduling fields may include:
 * - `executor`, `vus`, `iterations`, `stages`, `startVUs`, `gracefulStop`.
 *
 * @param {object} [thresholdOverrides] - Optional k6 threshold map merged on top
 *   of the selected profile defaults.
 * @returns {object} k6 scenario scheduling fields for launcher scenario entries.
 */
export function buildLauncherScenarioFromProfile(thresholdOverrides) {
  const profile = getProfile(); // Get the active test profile.
  // systemTags is top-level only; strip it here so it never ends up inside options.scenarios.*
  const { thresholds, noCookiesReset, systemTags, ...base } = buildScenarioFromProfile(thresholdOverrides);

  if (base.executor) {
    return base;
  }

  if (base.stages) {
    return {
      executor: 'ramping-vus',
      startVUs: 0,
      ...(profile === 'chaos' ? { gracefulStop: '30s' } : {}),
      ...base,
    };
  }

  return {
    executor: 'shared-iterations',
    ...base,
  };
}

/**
 * Creates a randomized `stages` array for ramping-vus execution.
 *
 * Each minute is represented by one stage entry (`duration: '1m'`).
 * The target VU count is chosen with two rules:
 * - idle stage: with probability `IDLE_STAGE_CHANCE`, target is 0
 * - active stage: otherwise, target is in [1..MAX_VUS]
 *
 * @param {number} minutes - Number of 1-minute stages to generate.
 * @returns {Array<{duration: string, target: number}>} k6 stage objects.
 */
export function generateRandomStages(minutes) {
  const stages = [];

  for (let i = 0; i < minutes; i++) {
    const randomVUs = Math.random() < IDLE_STAGE_CHANCE
                    ? 0
                    : Math.floor(Math.random() * MAX_VUS) + 1;
    stages.push({
      duration: '1m',
      target: randomVUs,
    });
  }

  return stages;
}

/**
 * Creates a full per-scenario chaos configuration for launcher scenario maps.
 *
 * This is used by launchers that declare many scenarios and want each one to
 * run with independent, randomized ramping-vus stages.
 *
 * k6 tags are key/value labels attached to metrics emitted by this scenario.
 * Here we set `profile: 'chaos'` so launcher thresholds can target only
 * chaos traffic, e.g. `http_req_failed{profile:chaos}`.
 * Without this tag, a threshold rule applies to all traffic in the test run.
 *
 * Each call increments an internal counter so scenarios are automatically
 * staggered by `SCENARIO_STAGGER_SECONDS` without the caller needing to
 * track or pass an index.
 *
 * @param {string} execName - Exported function name to execute for this scenario.
 * @returns {object} k6 scenario definition for one chaos scenario.
 */
let _chaosScenarioIndex = 0;
export function makeChaosScenario(execName) {
  const startDelay = _chaosScenarioIndex * SCENARIO_STAGGER_SECONDS;
  _chaosScenarioIndex++;
  return {
    executor: 'ramping-vus',
    exec: execName,
    startTime: `${startDelay}s`,
    startVUs: 0,
    stages: generateRandomStages(DURATION),
    tags: {
      profile: 'chaos',
      name: execName,
      params: `${DURATION} mins / ${MAX_VUS} vus`,
    },
    gracefulStop: '30s',
  };
}