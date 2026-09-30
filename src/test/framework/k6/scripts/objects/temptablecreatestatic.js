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

const RESOURCE_PATH = '/temptable/create/static';
const TABLE_NAMES = ['employee', 'customer', 'order', 'item', 'warehouse'];

export const options = buildScenarioFromProfile();

export default function () {
  ensureVirtualUserAuthenticated();
  const tableName = TABLE_NAMES[Math.floor(Math.random() * TABLE_NAMES.length)];

  const res = http.get(
    `${BASE_URL}${API_PREFIX}${OBJECTS_SERVICE}${RESOURCE_PATH}?tableName=${tableName}`,
    { headers: { Accept: 'application/json' }, tags: buildRequestTags(RESOURCE_PATH, 'object') }
  );

  const body = parseResponseBody(res);
  validateServiceResults(res, {
    'GET response status valid (OK)': (r) => r.status === 200,
    'API result value exists': () => body.result !== undefined,
    'API result is boolean': () => typeof body.result === 'boolean',
  });
  applyThinkTime(); // Optionally pause for a moment, depending on the profile in use.
}



