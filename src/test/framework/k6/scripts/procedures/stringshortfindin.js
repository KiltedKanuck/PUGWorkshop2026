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

const RESOURCE_PATH = '/string/short/findin';
const LETTERS = 'abcdefghijklmnopqrstuvwxyz';

export const options = buildScenarioFromProfile();

export default function () {
  ensureVirtualUserAuthenticated();
  const letter = LETTERS[Math.floor(Math.random() * LETTERS.length)];

  const res = http.get(
    `${BASE_URL}${API_PREFIX}${PROCEDURES_SERVICE}${RESOURCE_PATH}?letter=${letter}`,
    { headers: { Accept: 'application/json' }, tags: buildRequestTags(RESOURCE_PATH, 'procedure') }
  );

  const body = parseResponseBody(res);
  validateServiceResults(res, {
    'GET response status valid (OK)': (r) => r.status === 200,
    'API result value exists': () => body.result !== undefined,
    'API result is number': () => typeof body.result === 'number',
  });
  applyThinkTime(); // Optionally pause for a moment, depending on the profile in use.
}



