/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 */

/**
 * =============================
 * k6 Sample Execution Commands
 * =============================
 *
 * Single test executions using scenarios (profiles):
 *  k6 run --env BASE_URL=http://<host>:<port> scripts/<type>/<test>.js
 *   [Omitting PROFILE is the same as using "--env PROFILE=simple"]
 *  k6 run --env PROFILE=simple --env BASE_URL=http://<host>:<port> scripts/<type>/<test>.js
 *  k6 run --env PROFILE=smoke --env BASE_URL=http://<host>:<port> scripts/<type>/<test>.js
 *  k6 run --env PROFILE=load --env BASE_URL=http://<host>:<port> scripts/<type>/<test>.js
 *  k6 run --env PROFILE=stress --env BASE_URL=http://<host>:<port> scripts/<type>/<test>.js
 */

import {
  API_PREFIX,
  DATA_SERVICE,
} from '../../common/config.js';
import {
  getCreateRecordCount,
  getResourceConfig,
  resolveDependencyData,
  registerDependencyData,
  generateCreatePayloads,
  callRemoteEndpoint,
  createRecordAndCaptureKey,
  validateResponseContract,
  resolveRecord,
} from '../../common/crud.js';
import { setup as setupEmployee, teardown as teardownEmployee } from './employee.js';
import { buildScenarioFromProfile } from '../../common/scenarios.js';
import { defaultFieldFormatter, isLikelyNumericField, generateRunToken, updatedRecordValue, applyThinkTime } from '../../common/utils.js';

/*
 * =============================
 * k6 Init/Configuration Section
 * =============================
 * This section runs once when k6 loads the file.
 * It sets values used by setup(), default(), and teardown().
 */

/*
 * Set the intended resource for this test module.
 */
const RESOURCE_NAME = 'benefits';

/*
 * Runtime values from --env (with defaults).
 */
const API_PATH = __ENV.API_PATH || `${API_PREFIX}${DATA_SERVICE}/${RESOURCE_NAME}`;
const RUN_TOKEN = __ENV.RUN_TOKEN || generateRunToken();

/*
 * Create k6 scenario options based on the active profile.
 */
export const options = buildScenarioFromProfile();

/**
 * Per-resource validator for primary key fields in response data.
 * @param {string} fieldName - Field name.
 * @param {unknown} value - Response value.
 * @returns {boolean} True when value is valid for a PK field.
 */
function customPkFieldValidator(fieldName, value) {
  if (isLikelyNumericField(fieldName)) {
    return typeof value === 'number' && Number.isFinite(value);
  }
  return typeof value === 'string' && value.length > 0;
}

/**
 * Per-resource validator for non-key data fields in response data.
 * @param {string} fieldName - Field name.
 * @param {unknown} value - Response value.
 * @returns {boolean} True when value is valid for a data field.
 */
function customDataFieldValidator(fieldName, value) {
  if (isLikelyNumericField(fieldName)) {
    return typeof value === 'number' && Number.isFinite(value);
  }
  return typeof value === 'string';
}

/**
 * Produces the next update value for a mutable field.
 * @param {{[key: string]: unknown}} record - Current record.
 * @param {string} fieldName - Field name.
 * @returns {string|number} Next value for update.
 */
function nextUpdatedValue(record, fieldName) {
  if (isLikelyNumericField(fieldName)) {
    const current = Number(record[fieldName]);
    return Number.isFinite(current) ? current + 1 : 1;
  }
  return updatedRecordValue(record, fieldName);
}

/*
 * Extract the resource configuration and prepare records for creation.
 */
const RESOURCE_CONFIG = getResourceConfig(RESOURCE_NAME);
const UPDATE_FIELD_NAME = RESOURCE_CONFIG.data[0] || null;
const CALL_OPTIONS = {
  resourceName: RESOURCE_NAME,
  resourceConfig: RESOURCE_CONFIG,
  isValidResponseFn: validateResponseContract,
  pkFieldValidator: customPkFieldValidator,
  dataFieldValidator: customDataFieldValidator,
  apiPath: API_PATH,
};

/*
 * ============================
 * k6 Standard Execution Flow
 * ============================
 * 1) setup()    - create records once
 * 2) default()  - run test steps many times
 * 3) teardown() - clean up at the end
 */

/*
 * setup() runs once and creates one server record per payload in RESOURCE_CREATE_PAYLOADS.
 * Each created record keeps the server-generated primary key (when applicable) plus payload fields.
 * The script stores the returned object and passes it as `data` to default() and teardown().
 */
export function setup(setupContext = {}) {
  const { data: employeeData, owned: ownsEmployee, dependencyRegistry } = resolveDependencyData(setupContext, 'employee', setupEmployee);
  const employeeSource = Array.isArray(employeeData.records) ? employeeData.records : Object.values(employeeData.records || {});

  const RESOURCE_CREATE_PAYLOADS = generateCreatePayloads(RESOURCE_CONFIG, getCreateRecordCount(), RUN_TOKEN, defaultFieldFormatter);
  const createdRecords = [];
  for (let i = 0; i < RESOURCE_CREATE_PAYLOADS.length; i++) {
    const employeeRecord = employeeSource[i % employeeSource.length] || {};
    const record = {
      ...RESOURCE_CREATE_PAYLOADS[i],
      EmpNum: employeeRecord.EmpNum,
    };
    /* createRecordAndCaptureKey() POSTs one payload and returns the new primary key. */
    createdRecords.push(createRecordAndCaptureKey(record, CALL_OPTIONS));
  }
  /* Returned structure: data.records = [{ PK, Field1, ... FieldN }, ...] */
  const setupData = {
    records: createdRecords,
    employeeData,
    ownedDependencies: {
      employee: ownsEmployee,
    },
  };
  registerDependencyData({ dependencyRegistry }, 'benefits', setupData);
  return setupData;
}

/**
 * default() runs once per virtual user (VU) iteration.
 * Resolves one record (from the seeded pool or via a live GET against pre-existing data),
 * updates a field and PUTs the change.
 * @param {{records?: Array<{[key: string]: unknown}>|object}} data - setup() return payload.
 */
export default function runUserFlow(data) {
  const record = resolveRecord(data, CALL_OPTIONS);
  if (!record) return; // session-expiry cycle in progress; skip iteration
  if (UPDATE_FIELD_NAME) {
    record[UPDATE_FIELD_NAME] = nextUpdatedValue(record, UPDATE_FIELD_NAME);
  }
  callRemoteEndpoint('PUT', record, 'default', CALL_OPTIONS);
  applyThinkTime();
}

export function teardown(data) {
  /* teardown() runs once after all VUs and cleans up records created in setup(). */
  const source = Array.isArray(data.records) ? data.records : Object.values(data.records || {});
  for (const record of source) {
    callRemoteEndpoint('DELETE', record, 'teardown', CALL_OPTIONS);
  }

  if (data?.ownedDependencies?.employee) {
    teardownEmployee(data.employeeData);
  }
}


