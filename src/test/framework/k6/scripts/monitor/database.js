/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 *
 * k6 monitoring script - Database stats capture.
 *
 * Calls /system/database/list to resolve the first logical database name, then
 * calls /system/database/stats/{ldbname} and saves the JSON response body to
 * database_<timestamp>.json.
 *
 * Run this before and after a test to bookend database state. Each run produces
 * one timestamped file; the timestamps distinguish pre- and post-test captures.
 *
 * default() is a required no-op as it cannot write the output to a file.
 * handleSummary() makes both HTTP calls and writes the output file.
 *
 *   k6 run scripts/monitor/database.js
 *   k6 run --env SUMMARY_DIR=build/reports scripts/monitor/database.js
 */

import http from 'k6/http';
import { BASE_URL, MONITOR_PREFIX, SYSTEM_SERVICE } from '../../common/config.js';

const DB_LIST_PATH  = '/database/list';
const DB_STATS_PATH = '/database/stats';

const JSON_HEADERS = { Accept: 'application/json' };

/**
 * Single VU, single iteration — stats capture is a one-shot utility, not a load scenario.
 */
export const options = {
  vus: 1,
  iterations: 1,
};

/**
 * Formats a Unix millisecond timestamp as a filesystem-safe ISO-8601 string.
 * Colons are replaced with underscores — the only ISO-8601 character disallowed on Windows.
 * Example: 2026-07-28T19_03_05.711Z
 * @param {number} ms - Unix timestamp in milliseconds.
 * @returns {string} Filesystem-safe ISO-8601 timestamp string.
 */
function formatTimestamp(ms) {
  return new Date(ms).toISOString().replace(/:/g, '_');
}

/**
 * Calls /system/database/list and returns the first logical database name.
 * The list response is a JSON object keyed by logical database name.
 * @returns {string|null} First logical database name, or null on failure.
 */
function fetchDatabaseName() {
  const res = http.get(
    `${BASE_URL}${MONITOR_PREFIX}${SYSTEM_SERVICE}${DB_LIST_PATH}`,
    { headers: JSON_HEADERS }
  );

  if (res.status !== 200 || !res.body) {
    return null;
  }

  try {
    const list = JSON.parse(res.body);
    const keys = Object.keys(list);
    return keys.length > 0 ? keys[0] : null;
  } catch (_) {
    return null;
  }
}

/**
 * Calls /system/database/stats/{ldbname} and returns the raw JSON response body.
 * @param {string} ldbname - Logical database name returned by fetchDatabaseName().
 * @returns {string} Raw JSON response body, or empty string on failure.
 */
function fetchDatabaseStats(ldbname) {
  const res = http.get(
    `${BASE_URL}${MONITOR_PREFIX}${SYSTEM_SERVICE}${DB_STATS_PATH}/${ldbname}`,
    { headers: JSON_HEADERS }
  );

  if (res.status !== 200 || !res.body) {
    return '';
  }

  try {
    return JSON.stringify(JSON.parse(res.body), null, 2);
  } catch (_) {
    return String(res.body);
  }
}

/**
 * Required by k6; no work is done here.
 * Both HTTP calls and file output are handled entirely in handleSummary().
 */
export default function runUserFlow() {
}

/**
 * Resolves the first database name, fetches its stats, and writes the raw JSON
 * response to database_<timestamp>.json.
 * Network requests are available in handleSummary since k6 v0.43.0.
 * Output directory defaults to '.' and can be overridden with --env SUMMARY_DIR.
 * Example output: database_2026-07-28T19_03_05.711Z.json
 */
export function handleSummary() {
  const ldbname = fetchDatabaseName();
  const body    = ldbname ? fetchDatabaseStats(ldbname) : '';
  const ts        = formatTimestamp(Date.now());
  const outputDir = (__ENV.SUMMARY_DIR || '.').replace(/\/+$/, '');

  return {
    [`${outputDir}/database_${ts}.json`]: body,
  };
}

