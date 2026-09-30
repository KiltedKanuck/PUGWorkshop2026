/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 */

import http from 'k6/http';
import {
  BASE_URL,
  API_PREFIX,
  PROCEDURES_SERVICE
} from '../../common/config.js';
import { validateServiceResults, applyThinkTime, buildRequestTags, parseResponseBody } from '../../common/utils.js';
import { buildScenarioFromProfile } from '../../common/scenarios.js';
import { ensureVirtualUserAuthenticated } from '../../common/auth.js';

const RESOURCE_PATH = '/integer/division';

export const options = buildScenarioFromProfile();

/**
 * Calls /objects/integer/division with two random integers and validates
 * the HTTP status, result type, and computed quotient.
 * The server rounds to nearest integer (Math.round), not truncates.
 */
export default function () {
  ensureVirtualUserAuthenticated();
  const num1 = Math.floor(Math.random() * 1000);
  const num2 = Math.max(1, Math.floor(Math.random() * 1000));

  const res = http.get(
    `${BASE_URL}${API_PREFIX}${PROCEDURES_SERVICE}${RESOURCE_PATH}?num1=${num1}&num2=${num2}`,
    {
      headers: { Accept: 'application/json' },
      tags: buildRequestTags(RESOURCE_PATH, 'procedure'),
    }
  );

  const body = parseResponseBody(res);
  validateServiceResults(res, {
    'GET response status valid (OK)': (r) => r.status === 200,
    'API result is a number': () => typeof body.result === 'number',
    'API result equals Math.round(num1 / num2)': () => body.result === Math.round(num1 / num2),
  });
  applyThinkTime(); // Optionally pause for a moment, depending on the profile in use.
}



