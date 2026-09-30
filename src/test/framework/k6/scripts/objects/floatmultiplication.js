/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 */

import http from 'k6/http';
import {
  BASE_URL,
  API_PREFIX,
  OBJECTS_SERVICE
} from '../../common/config.js';
import { validateServiceResults, applyThinkTime, buildRequestTags, parseResponseBody } from '../../common/utils.js';
import { buildScenarioFromProfile } from '../../common/scenarios.js';
import { ensureVirtualUserAuthenticated } from '../../common/auth.js';

const RESOURCE_PATH = '/float/multiplication';

export const options = buildScenarioFromProfile();

/**
 * Calls /objects/float/multiplication with two random floats and validates
 * the HTTP status, result type, and computed product.
 */
export default function () {
  ensureVirtualUserAuthenticated();
  const num1 = parseFloat((Math.random() * 100).toFixed(4));
  const num2 = parseFloat((Math.random() * 100).toFixed(4));

  const res = http.get(
    `${BASE_URL}${API_PREFIX}${OBJECTS_SERVICE}${RESOURCE_PATH}?num1=${num1}&num2=${num2}`,
    {
      headers: { Accept: 'application/json' },
      tags: buildRequestTags(RESOURCE_PATH, 'object'),
    }
  );

  const body = parseResponseBody(res);
  validateServiceResults(res, {
    'GET response status valid (OK)': (r) => r.status === 200,
    'API result is a number': () => typeof body.result === 'number',
    'API result is a multiplication product': () => Math.abs(body.result - (num1 * num2)) < 0.01,
  });
  applyThinkTime(); // Optionally pause for a moment, depending on the profile in use.
}



