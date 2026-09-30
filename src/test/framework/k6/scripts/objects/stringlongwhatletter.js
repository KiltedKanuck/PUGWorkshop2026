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

const RESOURCE_PATH = '/string/long/whatletter';

/**
 * Returns a random integer in the inclusive range [min, max].
 *
 * Why min is guaranteed:
 * 1) Math.random() is in [0, 1)
 * 2) Multiply by span (max - min + 1) gives [0, span]
 * 3) Math.floor(...) gives an integer in [0, span - 1]
 * 4) Adding min shifts the range to [min, max]
 */
function randomIntInclusive(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

export const options = buildScenarioFromProfile();

export default function () {
  ensureVirtualUserAuthenticated();
  const loc = randomIntInclusive(1, 20); // 1-20

  const res = http.get(
    `${BASE_URL}${API_PREFIX}${OBJECTS_SERVICE}${RESOURCE_PATH}?loc=${loc}`,
    { headers: { Accept: 'application/json' }, tags: buildRequestTags(RESOURCE_PATH, 'object') }
  );

  const body = parseResponseBody(res);
  validateServiceResults(res, {
    'GET response status valid (OK)': (r) => r.status === 200,
    'API result value exists': () => body.result !== undefined,
    'API result is single character string': () => typeof body.result === 'string' && body.result.length === 1,
  });
  applyThinkTime(); // Optionally pause for a moment, depending on the profile in use.
}



