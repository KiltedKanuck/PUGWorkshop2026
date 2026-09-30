/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 */

import http from 'k6/http';
import {
  BASE_URL,
  API_PREFIX,
  ANOMALY_SERVICE,
  MIN_THINK_TIME,
  MAX_THINK_TIME
} from '../../common/config.js';
import { validateServiceResults, applyThinkTime, buildRequestTags, parseResponseBody } from '../../common/utils.js';
import { buildScenarioFromProfile } from '../../common/scenarios.js';
import { ensureVirtualUserAuthenticated } from '../../common/auth.js';

const RESOURCE_PATH = '/simulate/code/busy';

export const options = buildScenarioFromProfile();

/**
 * Calls /anomaly/simulate/code/busy with a specified busy time and validates
 * the HTTP status, result type, and elapsed time.
 */
export default function runUserFlow() {
  ensureVirtualUserAuthenticated();
  const randBusyTime = (MIN_THINK_TIME > 0 && MAX_THINK_TIME > 0)
                     ? Math.floor(MIN_THINK_TIME * 1000 + Math.random() * (MAX_THINK_TIME - MIN_THINK_TIME) * 1000)
                     : 2000; // Busy time in milliseconds; derived from think time config or default 2s

  const res = http.get(
    `${BASE_URL}${API_PREFIX}${ANOMALY_SERVICE}${RESOURCE_PATH}?busyTime=${randBusyTime}`,
    {
      headers: { Accept: 'application/json' },
      tags: buildRequestTags(RESOURCE_PATH, 'anomaly'),
    }
  );

  const body = parseResponseBody(res);
  validateServiceResults(res, {
    'GET response status valid (OK)': (r) => r.status === 200,
    'Elapsed time is a number': () => typeof body.elapsed === 'number'
  });
  applyThinkTime(); // Optionally pause for a moment, depending on the profile in use.
}



