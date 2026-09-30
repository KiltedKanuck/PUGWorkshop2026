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

const RESOURCE_PATH = '/string/short/hellojoin';
const WORDS = ['world', 'openedge', 'k6', 'test', 'load'];

export const options = buildScenarioFromProfile();

export default function () {
  ensureVirtualUserAuthenticated();
  const word = WORDS[Math.floor(Math.random() * WORDS.length)];

  const res = http.get(
    `${BASE_URL}${API_PREFIX}${OBJECTS_SERVICE}${RESOURCE_PATH}?word=${word}`,
    { headers: { Accept: 'application/json' }, tags: buildRequestTags(RESOURCE_PATH, 'object') }
  );

  const body = parseResponseBody(res);
  validateServiceResults(res, {
    'GET response status valid (OK)': (r) => r.status === 200,
    'API result value exists': () => body.result !== undefined,
    'API result is string': () => typeof body.result === 'string',
  });
  applyThinkTime(); // Optionally pause for a moment, depending on the profile in use.
}



