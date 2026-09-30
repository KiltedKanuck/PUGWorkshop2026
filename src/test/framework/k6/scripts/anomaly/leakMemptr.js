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

const RESOURCE_PATH = '/leak/code/memptr';

export const options = buildScenarioFromProfile();

/**
 * Calls /anomaly/leak/code/memptr to allocate a memptr that is intentionally not released
 * and validates the HTTP status.
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
    'GET response status valid (OK)': (r) => r.status === 200,
  });
  applyThinkTime();
}
