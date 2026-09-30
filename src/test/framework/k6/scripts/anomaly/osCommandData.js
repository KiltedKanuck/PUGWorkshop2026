/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 */

import http from 'k6/http';
import {
  BASE_URL,
  API_PREFIX,
  ANOMALY_SERVICE
} from '../../common/config.js';
import { validateServiceResults, applyThinkTime, buildRequestTags, parseResponseBody } from '../../common/utils.js';
import { buildScenarioFromProfile } from '../../common/scenarios.js';
import { ensureVirtualUserAuthenticated } from '../../common/auth.js';

const RESOURCE_PATH = '/files/oscommand/data';

export const options = buildScenarioFromProfile();

/**
 * Calls /anomaly/files/oscommand/data to read logging.config via OS-COMMAND and validates
 * the HTTP status and that file contents were returned.
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

  const body = parseResponseBody(res);
  validateServiceResults(res, {
    'GET response status valid (OK)': (r) => r.status === 200,
    'File contents returned': () => typeof body.fileContents === 'string' && body.fileContents.length > 0,
  });
  applyThinkTime();
}
