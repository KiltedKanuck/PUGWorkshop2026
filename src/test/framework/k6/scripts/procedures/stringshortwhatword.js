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

const RESOURCE_PATH = '/string/short/whatword';
const MAX_STRING_SIZE = 30000;
const MAX_LENGTH = Math.floor(MAX_STRING_SIZE / 2);

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
  // The CHARACTER implementation randomizes StringSize between 30000 and 32000.
  // Use the guaranteed lower bound so every test instance stays valid.
  // start >= 1, length >= 1, and start + length - 1 <= MAX_STRING_SIZE.
  const length = randomIntInclusive(1, MAX_LENGTH);
  const maxStart = MAX_STRING_SIZE - length + 1;
  const start = randomIntInclusive(1, maxStart);

  const res = http.get(
    `${BASE_URL}${API_PREFIX}${PROCEDURES_SERVICE}${RESOURCE_PATH}?start=${start}&length=${length}`,
    { headers: { Accept: 'application/json' }, tags: buildRequestTags(RESOURCE_PATH, 'procedure') }
  );

  const body = parseResponseBody(res);
  validateServiceResults(res, {
    'GET response status valid (OK)': (r) => r.status === 200,
    'API result value exists': () => body.result !== undefined,
    'API result is string': () => typeof body.result === 'string',
  });
  applyThinkTime(); // Optionally pause for a moment, depending on the profile in use.
}



