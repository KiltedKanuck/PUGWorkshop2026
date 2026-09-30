/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 */

import http from 'k6/http';
import {
  BASE_URL,
  API_PREFIX,
  ANOMALY_SERVICE
} from '../../common/config.js';
import { validateServiceResults, applyThinkTime, buildRequestTags } from '../../common/utils.js';
import { buildScenarioFromProfile } from '../../common/scenarios.js';
import { ensureVirtualUserAuthenticated } from '../../common/auth.js';

const RESOURCE_PATH = '/disrupt/code/quit';

export const options = buildScenarioFromProfile();

/**
 * Calls /anomaly/disrupt/code/quit to trigger a QUIT condition in the ABL session and validates
 * that the server returns the expected HTTP 500 error response.
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

  validateServiceResults(res, {
    'GET response status is server error (500)': (r) => r.status === 500,
  });
  applyThinkTime();
}
