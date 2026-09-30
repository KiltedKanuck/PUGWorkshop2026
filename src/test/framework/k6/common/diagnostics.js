/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 */

import execution from 'k6/execution';
import { Counter } from 'k6/metrics';

let ENABLE_FAILURE_DIAGNOSTICS = String(__ENV.ENABLE_FAILURE_DIAGNOSTICS || 'true').toLowerCase() === 'true';
let FAILURE_LOG_LIMIT_PER_VU = Math.max(0, parseInt(__ENV.FAILURE_LOG_LIMIT_PER_VU || '0', 10) || 0);
let FAILURE_BODY_SNIPPET_LENGTH = Math.max(80, parseInt(__ENV.FAILURE_BODY_SNIPPET_LENGTH || '1024', 10) || 1024);

/**
 * Applies diagnostics-related values from a resolved config env section.
 * Call this in launcher init context before export const options.
 * @param {object} env - The resolved config.env object from configLoader.loadConfig().
 */
export function applyDiagnosticsConfig(env) {
  if (!env) return;
  if (env.ENABLE_FAILURE_DIAGNOSTICS  !== undefined) ENABLE_FAILURE_DIAGNOSTICS  = Boolean(env.ENABLE_FAILURE_DIAGNOSTICS);
  if (env.FAILURE_LOG_LIMIT_PER_VU    !== undefined) {
    const n = parseInt(env.FAILURE_LOG_LIMIT_PER_VU, 10);
    FAILURE_LOG_LIMIT_PER_VU = Number.isFinite(n) ? Math.max(0, n) : 0;
  }
  if (env.FAILURE_BODY_SNIPPET_LENGTH !== undefined) {
    const n = parseInt(env.FAILURE_BODY_SNIPPET_LENGTH, 10);
    FAILURE_BODY_SNIPPET_LENGTH = Number.isFinite(n) ? Math.max(80, n) : 1024;
  }
}

const failureEvents = new Counter('debug_failure_events');

let failureLogCount = 0;
let failureLimitNoticeLogged = false;

function truncateValue(value, maxLength) {
  const source = String(value ?? '');
  if (source.length <= maxLength) {
    return source;
  }
  return `${source.substring(0, maxLength)}...(truncated)`;
}

function getContentType(response) {
  const headers = response?.headers;
  if (!headers || typeof headers !== 'object') {
    return '';
  }

  const raw = headers['Content-Type'] || headers['content-type'];
  if (Array.isArray(raw)) {
    return String(raw[0] || '').toLowerCase();
  }

  return String(raw || '').toLowerCase();
}

function getResponseHeader(response, headerName) {
  const headers = response?.headers;
  if (!headers || typeof headers !== 'object') {
    return '';
  }

  const lowerHeaderName = String(headerName || '').toLowerCase();
  const raw = headers[headerName]
    || headers[lowerHeaderName]
    || Object.entries(headers).find(([key]) => String(key).toLowerCase() === lowerHeaderName)?.[1];

  if (Array.isArray(raw)) {
    return String(raw[0] || '');
  }

  return String(raw || '');
}

function looksLikeJsonString(bodyText) {
  const trimmed = bodyText.trim();
  return trimmed.startsWith('{') || trimmed.startsWith('[');
}

function extractResponseBodySnippet(response) {
  if (!response || response.body === undefined || response.body === null) {
    return '';
  }

  if (typeof response.body === 'object') {
    try {
      return truncateValue(JSON.stringify(response.body), FAILURE_BODY_SNIPPET_LENGTH);
    } catch (err) {
      return '(unserializable-body)';
    }
  }

  if (typeof response.body === 'string') {
    const contentType = getContentType(response);
    const shouldTryJsonParse = contentType.includes('json') || looksLikeJsonString(response.body);

    if (shouldTryJsonParse) {
      try {
        return JSON.parse(response.body);
      }
      catch (err) {
        // Fall through to truncated string for non-JSON payloads or invalid JSON bodies.
      }
    }

    return truncateValue(response.body, FAILURE_BODY_SNIPPET_LENGTH);
  }

  try {
    return truncateValue(JSON.stringify(response.body), FAILURE_BODY_SNIPPET_LENGTH);
  }
  catch (err) {
    return '(unserializable-body)';
  }
}

function buildExecutionContext() {
  // execution.scenario is only available in VU context, not in setup/teardown
  try {
    const scenarioName = execution.scenario?.name || 'default';
    const vuId = execution.vu?.idInTest ?? __VU ?? 0;
    const iterNum = execution.vu?.iterationInScenario ?? __ITER ?? 0;
    return {
      scenario: scenarioName,
      vu: vuId,
      iteration: iterNum,
    };
  } catch (e) {
    // Outside VU context (setup/teardown phase)
    return {
      scenario: 'setup',
      vu: 0,
      iteration: 0,
    };
  }
}

function logFailureEvent(event) {
  if (!ENABLE_FAILURE_DIAGNOSTICS) {
    return;
  }

  if (FAILURE_LOG_LIMIT_PER_VU > 0 && failureLogCount >= FAILURE_LOG_LIMIT_PER_VU) {
    if (!failureLimitNoticeLogged) {
      failureLimitNoticeLogged = true;
      console.error(`[diag] failure log limit reached for this VU (${FAILURE_LOG_LIMIT_PER_VU}); suppressing further failure logs. Set FAILURE_LOG_LIMIT_PER_VU=0 to disable the cap.\n`);
    }
    return;
  }

  failureLogCount += 1;
  console.error('[diag] Failure Details:');
  console.error(JSON.stringify(event, null, 2) + "\n");
}

/**
 * Captures a structured failure event with bounded response body snippets.
 * @param {object} params - Failure context.
 * @param {string} params.failureType - Failure category (e.g. auth_login, crud_check).
 * @param {string[]} [params.failedChecks] - Names of failed checks, when available.
 * @param {import('k6/http').RefinedResponse<'text'>} [params.response] - HTTP response context.
 * @param {object} [params.metadata] - Additional contextual metadata.
 */
export function captureFailureContext(params) {
  const { failureType, failedChecks, response, metadata } = params;
  const exec = buildExecutionContext();

  const event = {
    ts: new Date().toISOString(),
    failureType,
    scenario: exec.scenario,
    vu: exec.vu,
    iteration: exec.iteration,
    agentSession: getResponseHeader(response, 'App-Agent-Session') || null,
    requestId: getResponseHeader(response, 'App-Request-ID') || null,
    method: response?.request?.method || '',
    url: response?.request?.url || '',
    status: response?.status,
    error: response?.error || '',
    errorCode: response?.error_code,
    failedChecks: Array.isArray(failedChecks) ? failedChecks : [],
    bodySnippet: extractResponseBodySnippet(response),
    timings: response?.timings
      ? { duration: response.timings.duration, waiting: response.timings.waiting }
      : null,
    metadata: metadata || {},
  };

  failureEvents.add(1, {
    failure_type: failureType || 'unknown',
    scenario: exec.scenario,
  });

  logFailureEvent(event);
}
