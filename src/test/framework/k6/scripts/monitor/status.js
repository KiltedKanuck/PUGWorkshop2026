/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 *
 * k6 monitoring script - PASOE status capture.
 *
 * Fetches /system/pasoe/report (plain text) and /system/pasoe/status (JSON)
 * and saves each to a timestamped file.
 *
 * Run this before and after a test to bookend server state. Each run produces
 * one pair of timestamped files; the timestamps distinguish pre- and post-test captures.
 *
 * default() is a required no-op as it cannot write the output to a file.
 * handleSummary() makes both HTTP calls and writes the output files.
 *
 *   k6 run scripts/monitor/status.js
 *   k6 run --env SUMMARY_DIR=build/reports scripts/monitor/status.js
 */

import http from 'k6/http';
import { BASE_URL, MONITOR_PREFIX, SYSTEM_SERVICE } from '../../common/config.js';

const REPORT_PATH = '/pasoe/report';
const STATUS_PATH = '/pasoe/status';

/**
 * Single VU, single iteration — status capture is a one-shot utility, not a load scenario.
 */
export const options = {
  vus: 1,
  iterations: 1,
};

/**
 * Issues a GET to /system/pasoe/report and returns the plain-text response body.
 * @returns {string} PASOE report response body.
 */
function fetchReport() {
  const res = http.get(
    `${BASE_URL}${MONITOR_PREFIX}${SYSTEM_SERVICE}${REPORT_PATH}`,
    { headers: { Accept: 'text/plain; charset=utf-8' } }
  );
  return res.status === 200 && res.body !== null ? String(res.body) : '';
}

/**
 * Issues a GET to /system/pasoe/status and returns the raw JSON response body.
 * @returns {string} PASOE status JSON response body.
 */
function fetchStatus() {
  const res = http.get(
    `${BASE_URL}${MONITOR_PREFIX}${SYSTEM_SERVICE}${STATUS_PATH}`,
    { headers: { Accept: 'application/json' } }
  );
  return res.status === 200 && res.body !== null ? String(res.body) : '{}';
}

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
 * Required by k6; no work is done here.
 * The HTTP call and file output are handled entirely in handleSummary().
 */
export default function runUserFlow() {
}

/**
 * Fetches PASOE report and status, writing both to timestamped files.
 * Network requests are available in handleSummary since k6 v0.43.0.
 * Output directory defaults to '.' and can be overridden with --env SUMMARY_DIR.
 * Example output: report_2026-07-28T19_03_05.711Z.txt, status_2026-07-28T19_03_05.711Z.json
 */
export function handleSummary() {
  const report = fetchReport();
  const status = fetchStatus();
  const ts = formatTimestamp(Date.now());
  const outputDir = (__ENV.SUMMARY_DIR || '.').replace(/\/+$/, '');

  return {
    [`${outputDir}/report_${ts}.txt`]: report,
    [`${outputDir}/status_${ts}.json`]: status,
  };
}

