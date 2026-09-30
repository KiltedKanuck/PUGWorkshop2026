/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 */

/**
 * @file serverTiming.js
 *
 * Utilities for extracting ABL server-side execution duration from the `Server-Timing`
 * HTTP response header and recording it as custom k6 Trend metrics.
 *
 * ## Standard
 *
 * The `Server-Timing` header is defined by the W3C Web Performance Working Group:
 *   "Server Timing" - W3C Working Draft (Recommendation track), 7 April 2026
 *   https://www.w3.org/TR/server-timing/
 *
 * The header is registered with IANA with status "standard" (§ 5.1 of the spec).
 * Note: the specification is a Working Draft and has not yet reached full W3C
 * Recommendation status.
 *
 * ## Header format (§ 2 of the spec - ABNF)
 *
 *   Server-Timing          = #server-timing-metric
 *   server-timing-metric   = metric-name *( OWS ";" OWS server-timing-param )
 *   server-timing-param    = server-timing-param-name OWS "=" OWS server-timing-param-value
 *   server-timing-param-name  = token
 *   server-timing-param-value = token / quoted-string
 *
 * Multiple comma-separated metrics may appear in a single header or across multiple
 * `Server-Timing` headers on the same response. The two defined param names are:
 *   - `dur`  - duration (milliseconds, floating-point, optional)
 *   - `desc` - description (string, optional)
 *
 * OpenEdge PASOE emits this header with metric name `app` and desc `"ABL"` to
 * report the time spent executing server-side ABL code:
 *   Server-Timing: app;desc="ABL";dur=7
 */

import { Trend } from 'k6/metrics';

/**
 * Custom k6 Trend metric for ABL server-side execution duration on CRUD endpoints.
 * Populated from the `server-timing: app;desc="ABL";dur=<ms>` response header.
 * Values are in milliseconds.
 */
export const ablDurationCrud = new Trend('abl_duration_crud', true);

/**
 * Custom k6 Trend metric for ABL server-side execution duration on non-CRUD endpoints
 * (objects, procedures, and other service types).
 * Populated from the `server-timing: app;desc="ABL";dur=<ms>` response header.
 * Values are in milliseconds.
 */
export const ablDurationOther = new Trend('abl_duration_other', true);

/**
 * Parses the `server-timing` response header value and returns the `dur` field
 * for the metric named `app`, or `null` when absent or unparseable.
 *
 * Implements the parsing algorithm described in § 2 of the W3C Server Timing
 * specification (https://www.w3.org/TR/server-timing/#the-server-timing-header-field).
 * The header is a comma-separated list of metric entries; each entry is a
 * metric name followed by optional semicolon-delimited `name=value` parameters.
 *
 * Example header value: `app;desc="ABL";dur=7`
 * The spec defines `dur` as a floating-point duration in milliseconds (§ 3.2).
 * When `dur` is absent on a metric entry the spec returns 0; this function
 * returns `null` in that case so callers can distinguish "not present" from "zero".
 *
 * @param {string} headerValue - Raw value of the `server-timing` header.
 * @returns {number|null} Duration in milliseconds, or null if not present or invalid.
 */
export function parseServerTimingDuration(headerValue) {
  if (!headerValue || typeof headerValue !== 'string') {
    return null;
  }

  const entries = headerValue.split(',');
  for (const entry of entries) {
    const parts = entry.trim().split(';');
    if (parts.length === 0) {
      continue;
    }

    const name = parts[0].trim();
    if (name !== 'app') {
      continue;
    }

    for (let i = 1; i < parts.length; i++) {
      const param = parts[i].trim();
      const eqIdx = param.indexOf('=');
      if (eqIdx < 0) {
        continue;
      }

      const key = param.slice(0, eqIdx).trim();
      if (key !== 'dur') {
        continue;
      }

      const rawValue = param.slice(eqIdx + 1).trim().replace(/^"(.*)"$/, '$1');
      const dur = parseFloat(rawValue);
      return Number.isFinite(dur) ? dur : null;
    }
  }

  return null;
}

/**
 * Reads the `server-timing` header from an HTTP response and records the ABL
 * execution duration into the appropriate custom k6 Trend metric.
 *
 * Silently skips recording when the header is absent or the `dur` value cannot
 * be parsed (e.g. the server did not emit timing data for this response).
 *
 * @param {import('k6/http').RefinedResponse<'text'>} res - HTTP response.
 * @param {string} apiType - API type tag for this request ('crud', 'object', 'procedure', etc.).
 *   Requests with apiType 'crud' are recorded in `abl_duration_crud`;
 *   all other types are recorded in `abl_duration_other`.
 */
export function recordAblDuration(res, apiType) {
  if (!res || !res.headers) {
    return;
  }

  // Use a case-insensitive lookup to handle k6 version differences in header key normalization.
  // k6 may store headers in canonical MIME form (Server-Timing), lowercase (server-timing),
  // or the original casing from the wire (HTTP/2 always sends lowercase; HTTP/1.1 varies).
  const headers = res.headers;
  const headerValue = Object.keys(headers).reduce((found, key) => {
    return found || (key.toLowerCase() === 'server-timing' ? headers[key] : '');
  }, '') || '';
  const dur = parseServerTimingDuration(headerValue);
  if (dur === null) {
    return;
  }

  if (apiType === 'crud') {
    ablDurationCrud.add(dur);
  }
  else {
    ablDurationOther.add(dur);
  }
}
