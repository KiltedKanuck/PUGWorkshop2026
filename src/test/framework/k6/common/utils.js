/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 */

import { check, sleep } from 'k6';
import { getProfile, DEFAULT_PROFILE, MIN_THINK_TIME, MAX_THINK_TIME } from './config.js';
import { captureFailureContext } from './diagnostics.js';
import { recordAblDuration } from './serverTiming.js';

/**
 * Prefixes a check name with a phase label when one is provided.
 * @param {string} phaseLabel - Phase label such as setup, default, or teardown.
 * @param {string} checkName - Original check name.
 * @returns {string} Phase-qualified check name.
 */
export function labelCheckName(phaseLabel, checkName) {
  const label = typeof phaseLabel === 'string' ? phaseLabel.trim() : '';
  const name = String(checkName || '').trim();

  if (!label) {
    return name;
  }

  return name.startsWith(`${label}: `) ? name : `${label}: ${name}`;
}

/**
 * Analyzes response body type and parse status for diagnostics and safe parsing.
 *
 * @param {import('k6/http').RefinedResponse<'text'>} res - HTTP response.
 * @returns {{kind: 'empty' | 'json' | 'text', body: object, json: object|null, text: string, contentType: string, parseError: string|null}}
 *          Parsed response payload metadata.
 */
function analyzeResponseBody(res) {
  const rawBody = res && res.body !== undefined && res.body !== null ? String(res.body) : '';
  const trimmedBody = rawBody.trim();
  const rawContentType = res?.headers?.['Content-Type'] || res?.headers?.['content-type'] || '';
  const contentType = Array.isArray(rawContentType) ? String(rawContentType[0] || '') : String(rawContentType || '');

  if (!trimmedBody) {
    return {
      kind: 'empty',
      body: {},
      json: null,
      text: '',
      contentType,
      parseError: null,
    };
  }

  const contentTypeLower = contentType.toLowerCase();
  const firstChar = trimmedBody[0];
  const shouldAttemptJson =
    contentTypeLower.includes('application/json')
    || contentTypeLower.includes('+json')
    || firstChar === '{'
    || firstChar === '[';

  if (shouldAttemptJson) {
    const parsedJson = parseJsonBody(res);
    if (parsedJson !== null) {
      return {
        kind: 'json',
        body: parsedJson,
        json: parsedJson,
        text: rawBody,
        contentType,
        parseError: null,
      };
    }

    return {
      kind: 'text',
      body: {},
      json: null,
      text: rawBody,
      contentType,
      parseError: 'json_parse_failed',
    };
  }

  return {
    kind: 'text',
    body: {},
    json: null,
    text: rawBody,
    contentType,
    parseError: null,
  };
}

/**
 * Parses a response body for test assertions.
 *
 * Returns parsed JSON object when available, otherwise an empty object.
 * This function never throws.
 *
 * @param {import('k6/http').RefinedResponse<'text'>} res - HTTP response.
 * @returns {object} Parsed JSON object or an empty object.
 */
export function parseResponseBody(res) {
  return analyzeResponseBody(res).body;
}

function parseResponseMetadata(res) {
  const analyzed = analyzeResponseBody(res);
  return {
    responseBodyKind: analyzed.kind,
    responseContentType: analyzed.contentType || 'unknown',
    responseParseError: analyzed.parseError,
  };
}

/**
 * Parses response body JSON safely.
 * @param {import('k6/http').RefinedResponse<'text'>} res - HTTP response.
 * @returns {object|null} Parsed JSON object when available.
 */
export function parseJsonBody(res) {
  if (!res || res.body === undefined || res.body === null) {
    return null;
  }

  const rawBody = String(res.body).trim();
  if (!rawBody) {
    return null;
  }

  try {
    return JSON.parse(rawBody);
  }
  catch (err) {
    return null;
  }
}

/**
 * Detects server-side error payload shape.
 * @param {object|null} body - Parsed JSON body.
 * @returns {boolean} True when payload matches known server error structure.
 */
export function hasServerErrorResponse(body) {
  return !!(
    body
    && Array.isArray(body._errors)
    && body._errors.length > 0
    && typeof body._errors[0] === 'object'
  );
}

/**
 * Returns an updated field value by appending a random hash.
 * @param {{[key: string]: unknown}} record - Source record object.
 * @param {string} fieldName - Field to update.
 * @returns {string} Updated field value.
 */
export function updatedRecordValue(record, fieldName) {
  const sourceValue = String(record?.[fieldName] || fieldName); // Get current field value, or fall back to field name when absent or empty string.
  const randomHash = Math.random().toString(36).slice(2, 10); // 8-char random alphanumeric string.
  return `${sourceValue}-${randomHash}`;
}

/**
 * Builds request tags with the active profile baked in.
 * Consolidates tag construction for procedure and object scripts.
 *
 * @param {string} resourcePath - Logical resource name for this operation.
 * @param {string} [apiType='service'] - Logical API namespace (e.g. procedure, object, crud).
 * @returns {object} Tags object with stable endpoint grouping fields.
 */
export function buildRequestTags(resourcePath, apiType = 'service') {
  return {
    // 'name' is the k6 URL grouping override - it replaces the raw request URL (including
    // dynamic query parameters) as the metric series key. Must be listed first and must
    // remain a stable, parameter-free label so all requests to the same logical endpoint
    // collapse into a single metric series rather than producing unbounded cardinality.
    name: resourcePath,
    apiType,
    resource: resourcePath,
    profile: getProfile(),
  };
}

/**
 * Runs named result checks for service scripts and captures detailed diagnostics when they fail.
 *
 * This preserves k6 check metric behavior while adding per-failure context via diagnostics capture.
 *
 * @param {import('k6/http').RefinedResponse<'text'>} response - HTTP response to validate.
 * @param {Record<string, (response: import('k6/http').RefinedResponse<'text'>) => boolean>} checks - Named predicates.
 * @param {{failureType?: string, metadata?: object, apiType?: string}} [options] - Optional diagnostics context.
 *   `apiType` is forwarded to ABL duration tracking; defaults to 'other' when omitted.
 * @returns {boolean} True when all checks passed.
 */
export function validateServiceResults(response, checks, options = {}) {
  recordAblDuration(response, options.apiType || 'other');
  const checkLabel = options.checkLabel || 'default';
  const checkMap = {};
  const evaluatedResults = {};
  const predicateErrors = {};

  for (const [checkName, predicate] of Object.entries(checks || {})) {
    const labeledCheckName = labelCheckName(checkLabel, checkName);
    let result;
    try {
      result = Boolean(predicate(response));
    }
    catch (err) {
      result = false;
      predicateErrors[labeledCheckName] = String(err && err.message ? err.message : err);
    }
    evaluatedResults[labeledCheckName] = result;
    checkMap[labeledCheckName] = () => result;
  }

  const passed = check(response, checkMap);

  if (!passed) {
    const failedChecks = Object.entries(evaluatedResults)
      .filter(([, checkPassed]) => !checkPassed)
      .map(([checkName]) => checkName);

    const responseParseMetadata = parseResponseMetadata(response);

    if (!responseParseMetadata.responseParseError) {
      delete responseParseMetadata.responseParseError;
    }

    captureFailureContext({
      failureType: options.failureType || 'service_result_failure',
      failedChecks,
      response,
      metadata: {
        ...(options.metadata || {}),
        predicateErrors,
        ...responseParseMetadata,
      },
    });
  }

  return passed;
}

/**
 * Applies a profile-appropriate think time pause at the end of a VU iteration.
 *
 * - smoke / simple: no pause (deterministic correctness checks, not load simulation).
 * - load / stress:  fixed pause of MIN_THINK_TIME seconds.
 * - chaos:          random pause uniformly drawn from [MIN_THINK_TIME, MAX_THINK_TIME].
 */
export function applyThinkTime() {
  const profile = getProfile(); // Get the active test profile.
  if (profile === 'smoke' || profile === DEFAULT_PROFILE) {
    return;
  }

  const duration = profile === 'chaos'
                 ? MIN_THINK_TIME + Math.random() * (MAX_THINK_TIME - MIN_THINK_TIME)
                 : MIN_THINK_TIME;

  sleep(duration);
}

/**
 * Generates a unique 6-digit run token for seeding deterministic CRUD data values.
 * Uses XOR of timestamp milliseconds and a random value to eliminate NTP clock-sync
 * collision risk when multiple test nodes start concurrently.
 * @returns {string} 6-digit zero-padded token string.
 */
export function generateRunToken() {
  const ms  = Date.now() % 1000000;
  const rnd = Math.floor(Math.random() * 1000000);
  return String((ms ^ rnd) % 1000000).padStart(6, '0');
}

/**
 * Basic heuristic for numeric-like fields when crafting test data.
 * Returns true when the field name ends in a common numeric suffix.
 * @param {string} fieldName - Field name.
 * @returns {boolean} True when field usually carries numeric values.
 */
export function isLikelyNumericField(fieldName) {
  return /(Num|ID|Key|Sequence|LineNum|Amount)$/i.test(fieldName);
}

/**
 * Basic heuristic for date-like fields when crafting test data.
 * Returns true when the field name ends in a common date suffix.
 * @param {string} fieldName - Field name.
 * @returns {boolean} True when field usually carries a calendar date value.
 */
export function isLikelyDateField(fieldName) {
  return /(Date|Recorded|Timestamp)$/i.test(fieldName);
}

/**
 * Default field value formatter for CRUD test data generation.
 * Applies type heuristics in priority order: date fields return an ISO 8601 calendar
 * date string, numeric fields return an integer index, and all other fields return an
 * OELS-prefixed string token. The _isKey parameter is accepted for interface
 * compatibility with custom formatters but is not used.
 * @param {string} fieldName - Field name.
 * @param {number} index - Zero-based payload index.
 * @param {string} runToken - Run token.
 * @param {boolean} _isKey - Unused; present for interface compatibility with custom formatters.
 * @returns {string|number} Formatted field value.
 */
export function defaultFieldFormatter(fieldName, index, runToken, _isKey) {
  if (isLikelyDateField(fieldName)) {
    return new Date(Date.UTC(2026, 0, 1 + index)).toISOString().slice(0, 10);
  }
  if (isLikelyNumericField(fieldName)) {
    return index + 1;
  }
  return `OELS-${fieldName.toUpperCase()}-${String(index + 1).padStart(6, '0')}-${runToken}`;
}
