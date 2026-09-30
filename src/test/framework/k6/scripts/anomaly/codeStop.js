/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 */

import http from 'k6/http';
import {
  BASE_URL,
  API_PREFIX,
  ANOMALY_SERVICE
} from '../../common/config.js';
import { validateServiceResults, applyThinkTime, buildRequestTags, parseResponseBody } from '../../common/utils.js';
import { buildScenarioFromProfile } from '../../common/scenarios.js';
import { ensureVirtualUserAuthenticated } from '../../common/auth.js';

const RESOURCE_PATH = '/disrupt/code/stop';

export const options = buildScenarioFromProfile();

/**
 * Calls /anomaly/disrupt/code/stop to trigger a STOP condition in the ABL session and validates
 * that the server returns the expected HTTP 408 timeout response with the stop error body.
 */
export default function runUserFlow() {
  ensureVirtualUserAuthenticated();

  const res = http.get(
    `${BASE_URL}${API_PREFIX}${ANOMALY_SERVICE}${RESOURCE_PATH}`,
    {
      headers: { Accept: 'application/json' },
      tags: buildRequestTags(RESOURCE_PATH, 'anomaly'),
    }
  );

  const body = parseResponseBody(res);
  validateServiceResults(res, {
    'GET response status is timeout (408)': (r) => r.status === 408,
    'Response contains stop error': () => Array.isArray(body._errors) && body._errors[0]?._errorNum === 408,
  });
  applyThinkTime();
}
