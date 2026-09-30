/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 */

/**
 * This module provides common utilities for CRUD operation tests, which may also require authentication.
 * See the common/auth.js for more information about the lifecycle for authentication in k6 tests.
 *
 * ## Session Expiry Flow
 *
 * When `AUTH_SESSION_DURATION_SECONDS > 0`, each VU session has a finite lifetime. Once that
 * threshold is crossed, the session must be invalidated and a new one established before the
 * next iteration runs. The intended behaviour is strictly either/or per iteration:
 *
 *   - **Normal iteration**: `resolveRecord()` succeeds → GET → PUT → `applyThinkTime()`.
 *   - **Expiry iteration**: expiry is detected at the start → invalidation/logout cycle runs →
 *     iteration is skipped cleanly. The VU re-authenticates on the following iteration.
 *
 * A session that expires *mid-iteration* does NOT interrupt the current flow. The VU is allowed
 * to finish the GET and PUT it already started. On the *next* iteration the expiry condition is
 * still true and the expiry cycle fires then.
 *
 * ### Check points
 *
 * 1. **`resolveRecord()` - iteration gate (primary check)**
 *    `handleSessionDurationExpiry()` is the very first call in `resolveRecord`, which is always
 *    the first call in every `runUserFlow`. If it returns `true`, `resolveRecord` returns `null`
 *    immediately - no HTTP traffic, no record mutation.
 *
 * 2. **Individual script callers - `if (!record) return;`**
 *    Every CRUD script checks the return value of `resolveRecord`. A `null` result means the
 *    expiry cycle is in progress; the iteration exits without a GET or PUT.
 *
 * Full call chain summary:
 * ```
 * runUserFlow()
 *   └─ resolveRecord()
 *        ├─ handleSessionDurationExpiry() → true  → return null  [check 1: iteration gate]
 *        ├─ handleSessionDurationExpiry() → false → continue
 *        │    └─ GET record → PUT record                          [normal CRUD path]
 *   caller: if (!record) return;                                  [check 2: clean skip]
 * ```
 */

import http from 'k6/http';
import { check, fail, sleep } from 'k6';
import { getProfile, DEFAULT_PROFILE, BASE_URL, API_PREFIX, DATA_SERVICE, MAX_VUS, SEED_RECORD_MAX } from './config.js';
import { ensureAuthenticationIfRequired, handleSessionDurationExpiry } from './auth.js';

/**
 * Fixed epoch (ms since Unix epoch) for deterministic date-keyed record generation.
 * Adding a record ID (as minutes) to this value produces a unique, reproducible
 * date per record. Must match dtzDateEpoch in GenSportsData.p.
 */
export const DATE_EPOCH_MS = new Date('2025-01-01T00:00:00Z').getTime();
import { JSON_ACCEPT_HEADERS, JSON_HEADERS } from './headers.js';
import { labelCheckName, parseJsonBody, hasServerErrorResponse } from './utils.js';
import { expectedResults } from './expectations.js';
import { captureFailureContext } from './diagnostics.js';
import { recordAblDuration } from './serverTiming.js';

function truncateValue(value, maxLength) {
  const source = String(value ?? '');
  if (source.length <= maxLength) {
    return source;
  }
  return `${source.substring(0, maxLength)}...(truncated)`;
}

function summarizeResponseBody(body) {
  if (!body) {
    return 'n/a';
  }

  if (typeof body === 'string') {
    return truncateValue(body, 240);
  }

  if (typeof body !== 'object') {
    return truncateValue(body, 240);
  }

  const topLevelError = Array.isArray(body._errors) && body._errors.length > 0
    ? body._errors[0]
    : null;
  const innerError = topLevelError && topLevelError._innerError && Array.isArray(topLevelError._innerError._errors)
    && topLevelError._innerError._errors.length > 0
    ? topLevelError._innerError._errors[0]
    : null;

  const parts = [];
  if (typeof body._retVal === 'string' && body._retVal !== '') {
    parts.push(`retVal=${truncateValue(body._retVal, 120)}`);
  }
  if (topLevelError) {
    if (topLevelError._errorMsg) parts.push(`error=${truncateValue(topLevelError._errorMsg, 120)}`);
    if (topLevelError._errorNum !== undefined && topLevelError._errorNum !== null) parts.push(`errorNum=${topLevelError._errorNum}`);
    if (topLevelError._sev !== undefined && topLevelError._sev !== null) parts.push(`severity=${topLevelError._sev}`);
  }
  if (innerError) {
    if (innerError._errorMsg) parts.push(`innerError=${truncateValue(innerError._errorMsg, 120)}`);
    if (innerError._device) parts.push(`device=${innerError._device}`);
    if (innerError._tableName) parts.push(`table=${innerError._tableName}`);
    if (innerError._user) parts.push(`user=${innerError._user}`);
  }

  return parts.length > 0 ? parts.join(', ') : truncateValue(JSON.stringify(body), 240);
}

function buildFailMessage(method, resourceName, pkPairs, res, expectedResult, parsedBody) {
  const bodySummary = summarizeResponseBody(parsedBody || res.body);
  return `[fail] ${method} ${resourceName} failed for ${pkPairs}: status=${res.status}, expected=${expectedResult.join('|')}, bodySummary=${bodySummary}\n`;
}

/**
 * Returns true when the test run is responsible for creating and deleting seed records.
 * When false (the default), records are assumed to already exist in the database, and
 * setup()/teardown() CRUD seeding logic is skipped entirely.
 *
 * Controlled by the CREATE_SEED_RECORDS env flag (JSON boolean, default false).
 * k6 env vars are always strings at runtime, so the explicit string 'true' is required.
 */
export function shouldCreateSeedRecords() {
  return __ENV.CREATE_SEED_RECORDS === 'true';
}

/**
 * Get the number of records to create (seed) during setup().
 * Evaluated lazily to respect profile overrides set before imports.
 *
 * Returns 0 immediately when CREATE_SEED_RECORDS is false, causing all setup()
 * loops to produce empty record arrays and teardown() loops to skip deletions.
 *
 * Scales the seeded record pool as a VU-to-record ratio divisor, so contention behavior
 * tracks MAX_VUS automatically when VU count changes.
 *
 * Formula: record_count = round(MAX_VUS / SEED_RECORD_RATIO), minimum 1.
 * SEED_RECORD_RATIO expresses how many VUs compete per record (X:1).
 *
 * Profile-aware defaults:
 * - smoke/simple: always 1 record (minimal correctness check, matches 1 iteration).
 * - other profiles: ratio 1 seeds exactly MAX_VUS records (1 VU per record, no contention).
 *
 * User override via --env SEED_RECORD_RATIO=<integer> applies to any profile.
 * Ratio 1 (default): 1 VU per record - no contention.
 * Ratio 2: 2 VUs per record - light contention.
 * Ratio 4: 4 VUs per record - high contention.
 * Minimum enforced ratio is 1. Minimum enforced record count is always 1.
 */
export function getCreateRecordCount() {
  if (!shouldCreateSeedRecords()) return 0;
  const ratio = Math.max(1, parseInt(__ENV.SEED_RECORD_RATIO, 10) || 1);
  const currentProfile = getProfile();
  if (currentProfile === 'smoke' || currentProfile === DEFAULT_PROFILE) {
    return 1; // Purposefully limited to a single record for these low-volume profiles.
  }
  return Math.max(1, Math.round(MAX_VUS / ratio));
}

/**
 * =============================
 * Resource Registry
 * =============================
 * Maps each CRUD resource to its database table metadata.
 *
 * Properties per entry:
 *   table     - Database table name (PascalCase).
 *   pkFields  - Ordered array of primary key field descriptors as returned in API JSON responses.
 *               Each entry is an object: { name: string, type: 'integer'|'string'|'date' }.
 *               'integer' - numeric PK (server-sequenced or caller-supplied integer FK).
 *               'string'  - natural/character PK (caller-supplied, uses OELS-<FIELD>-<N> pattern).
 *               'date'    - date PK synthesized as DATE_EPOCH_MS plus recordId minutes, formatted YYYY-MM-DD.
 *   sequenced - true when the server assigns the PK via a Next<name> sequence on create,
 *               meaning the caller must NOT include the PK in the POST payload and must
 *               capture the server-returned value.
 *               false when the caller supplies the PK in the POST payload.
 *   data      - Non-key fields expected by create/update calls (derived from OpenAPI POST/PUT).
 *
 * Note that certain tables have dependencies on others:
 *   Benefits: Employee.EmpNum
 *   BillTo: Customer.CustNum
 *   Bin: Warehouse.WarehouseNum, Item.ItemNum
 *   Customer: SalesRep.SalesRep
 *   Employee: Department.DeptCode
 *   Family: Employee.EmpNum
 *   InventoryTrans: Item.ItemNum
 *   Invoice: Customer.CustNum
 *   Order: Customer.CustNum
 *   OrderLine: Order.OrderNum, Item.ItemNum
 *   PurchaseOrder: Supplier.SupplierIDNum
 *   POLine: Item.ItemNum, PurchaseOrder.PONum
 *   ShipTo: Customer.CustNum
 *   SupplierItemXref: Supplier.SupplierIDNum, Item.ItemNum
 *   Timesheet: Employee.EmpNum
 *   Vacation: Employee.EmpNum
 */
export const RESOURCE_REGISTRY = Object.freeze({
  benefits:         { table: 'Benefits',         pkFields: [{ name: 'EmpNum',        type: 'integer' }],                                            sequenced: false, data: [] },
  billto:           { table: 'BillTo',           pkFields: [{ name: 'CustNum',       type: 'integer' }, { name: 'BillToID',     type: 'integer' }], sequenced: false, data: ['Name'] },
  bin:              { table: 'Bin',              pkFields: [{ name: 'BinNum',        type: 'integer' }],                                            sequenced: true,  data: ['BinName'] },
  customer:         { table: 'Customer',         pkFields: [{ name: 'CustNum',       type: 'integer' }],                                            sequenced: true,  data: ['Name', 'Comments', 'Phone', 'Contact', 'EmailAddress', 'Terms'] },
  department:       { table: 'Department',       pkFields: [{ name: 'DeptCode',      type: 'string'  }],                                            sequenced: false, data: ['DeptName'] },
  employee:         { table: 'Employee',         pkFields: [{ name: 'EmpNum',        type: 'integer' }],                                            sequenced: true,  data: ['FirstName', 'LastName', 'DeptCode', 'Position'] },
  family:           { table: 'Family',           pkFields: [{ name: 'EmpNum',        type: 'integer' }, { name: 'RelativeName', type: 'string'  }], sequenced: false, data: [] },
  feedback:         { table: 'Feedback',         pkFields: [{ name: 'Department',    type: 'string'  }],                                            sequenced: false, data: ['Comments'] },
  inventorytrans:   { table: 'InventoryTrans',   pkFields: [{ name: 'InvTransNum',   type: 'integer' }],                                            sequenced: true,  data: [] },
  invoice:          { table: 'Invoice',          pkFields: [{ name: 'InvoiceNum',    type: 'integer' }],                                            sequenced: true,  data: ['Amount'] },
  item:             { table: 'Item',             pkFields: [{ name: 'ItemNum',       type: 'integer' }],                                            sequenced: true,  data: ['CatDescription', 'ItemName', 'Category1', 'Category2'] },
  localdefault:     { table: 'LocalDefault',     pkFields: [{ name: 'LocalDefNum',   type: 'integer' }],                                            sequenced: true,  data: [] },
  order:            { table: 'Order',            pkFields: [{ name: 'OrderNum',      type: 'integer' }],                                            sequenced: true,  data: ['CustNum', 'Instructions', 'Carrier', 'Terms', 'OrderStatus'] },
  orderline:        { table: 'OrderLine',        pkFields: [{ name: 'OrderNum',      type: 'integer' }, { name: 'LineNum',      type: 'integer' }], sequenced: false, data: ['OrderLineStatus'] },
  poline:           { table: 'POLine',           pkFields: [{ name: 'PONum',         type: 'integer' }, { name: 'LineNum',      type: 'integer' }], sequenced: false, data: [] },
  purchaseorder:    { table: 'PurchaseOrder',    pkFields: [{ name: 'PONum',         type: 'integer' }],                                            sequenced: true,  data: [] },
  refcall:          { table: 'RefCall',          pkFields: [{ name: 'CallNum',       type: 'integer' }],                                            sequenced: true,  data: ['CustNum', 'Parent'] },
  salesrep:         { table: 'SalesRep',         pkFields: [{ name: 'SalesRep',      type: 'string'  }],                                            sequenced: false, data: ['RepName', 'Region'] },
  shipto:           { table: 'ShipTo',           pkFields: [{ name: 'CustNum',       type: 'integer' }, { name: 'ShipToID',     type: 'integer' }], sequenced: false, data: ['Name', 'Comments'] },
  state:            { table: 'State',            pkFields: [{ name: 'State',         type: 'string'  }],                                            sequenced: false, data: ['StateName'] },
  supplier:         { table: 'Supplier',         pkFields: [{ name: 'SupplierIDNum', type: 'integer' }],                                            sequenced: true,  data: ['Name', 'Comments', 'ShipAmount'] },
  supplieritemxref: { table: 'SupplierItemXref', pkFields: [{ name: 'SupplierIDNum', type: 'integer' }, { name: 'ItemNum',      type: 'integer' }], sequenced: false, data: [] },
  timesheet:        { table: 'TimeSheet',        pkFields: [{ name: 'EmpNum',        type: 'integer' }, { name: 'DayRecorded',  type: 'date'    }], sequenced: false, data: [] },
  vacation:         { table: 'Vacation',         pkFields: [{ name: 'EmpNum',        type: 'integer' }, { name: 'StartDate',    type: 'date'    }], sequenced: false, data: [] },
  warehouse:        { table: 'Warehouse',        pkFields: [{ name: 'WarehouseNum',  type: 'integer' }],                                            sequenced: true,  data: ['WarehouseName', 'Address', 'City', 'State', 'Phone'] },
});

/**
 * Retrieves a single resource configuration from the registry.
 * @param {string} resourceName - Resource name (lowercase).
 * @returns {object} Resource registry entry with pkFields, sequenced, data properties.
 * @throws {Error} If resourceName is not found in RESOURCE_REGISTRY.
 */
export function getResourceConfig(resourceName) {
  const config = RESOURCE_REGISTRY[resourceName];
  if (!config) {
    throw new Error(`Missing RESOURCE_REGISTRY entry for '${resourceName}'`);
  }
  return config;
}

/**
 * Returns a dependency registry object from setup context.
 * Creates a new empty registry when one is not provided.
 * @param {{dependencyRegistry?: {[key: string]: unknown}}} [setupContext] - Optional setup context.
 * @returns {{[key: string]: unknown}} Dependency registry.
 */
export function getDependencyRegistry(setupContext) {
  if (setupContext && typeof setupContext === 'object' && setupContext.dependencyRegistry && typeof setupContext.dependencyRegistry === 'object') {
    return setupContext.dependencyRegistry;
  }
  return {};
}

/**
 * Registers setup data in a dependency registry and returns the registry.
 * @param {{dependencyRegistry?: {[key: string]: unknown}}} [setupContext] - Optional setup context.
 * @param {string} dependencyKey - Registry key for this setup data.
 * @param {unknown} setupData - Setup data to register.
 * @returns {{[key: string]: unknown}} Dependency registry.
 */
export function registerDependencyData(setupContext, dependencyKey, setupData) {
  const dependencyRegistry = getDependencyRegistry(setupContext);
  dependencyRegistry[dependencyKey] = setupData;
  return dependencyRegistry;
}

/**
 * Resolves dependency setup data from registry or seeds it when missing.
 * @param {{dependencyRegistry?: {[key: string]: unknown}}} [setupContext] - Optional setup context.
 * @param {string} dependencyKey - Registry key for dependency data.
 * @param {Function} setupFn - Setup function used when dependency is missing.
 * @returns {{data: unknown, owned: boolean, dependencyRegistry: {[key: string]: unknown}}}
 * Dependency data, ownership flag, and registry.
 */
export function resolveDependencyData(setupContext, dependencyKey, setupFn) {
  const dependencyRegistry = getDependencyRegistry(setupContext);
  if (dependencyRegistry[dependencyKey]) {
    return {
      data: dependencyRegistry[dependencyKey],
      owned: false,
      dependencyRegistry,
    };
  }

  const seededData = setupFn({ dependencyRegistry });
  dependencyRegistry[dependencyKey] = seededData;
  return {
    data: seededData,
    owned: true,
    dependencyRegistry,
  };
}

/**
 * Generates CREATE payloads for a resource based on registry metadata.
 * @param {object} resourceConfig - Resource registry entry with pkFields, sequenced, data.
 * @param {number} count - Number of payloads to generate.
 * @param {string} runToken - Unique token to seed deterministic values.
 * @param {Function} [fieldValueFormatter] - Optional function(fieldName, index, runToken, isKey) => value.
 * @returns {Array<object>} Array of CREATE payloads.
 */
export function generateCreatePayloads(resourceConfig, count, runToken, fieldValueFormatter) {
  const { pkFields, data: dataFields, sequenced: isSequenced } = resourceConfig;

  return Array.from({ length: count }, (_, i) => {
    const payload = {};

    // Add primary key fields only if NOT server-sequenced.
    if (!isSequenced) {
      pkFields.forEach((f) => {
        payload[f.name] = fieldValueFormatter
                        ? fieldValueFormatter(f.name, i, runToken, true)
                        : i + 1;
      });
    }

    // Add data fields.
    dataFields.forEach((f) => {
      payload[f] = fieldValueFormatter
                 ? fieldValueFormatter(f, i, runToken, false)
                 : `OELS-${f}-${String(i + 1).padStart(6, '0')}-${runToken}`;
    });

    return payload;
  });
}

/**
 * Builds the endpoint URL for a resource.
 * @param {string} method - HTTP method: POST, GET, PUT, or DELETE.
 * @param {{[key: string]: unknown}} record - Record containing primary key and supporting fields.
 * @param {object} resourceConfig - Resource registry entry with pkFields, data, sequenced.
 * @param {string} apiPath - API endpoint path.
 * @returns {string} Fully qualified request URL.
 * @throws {Error} If method is not one of the supported methods (CRUD operations).
 */
export function buildUrl(method, record, resourceConfig, apiPath) {
  const { pkFields, data: dataFields, sequenced: isSequenced } = resourceConfig;
  const pkParams = pkFields.map((f) => `${f.name}=${encodeURIComponent(record[f.name])}`).join('&');
  const dataParams = dataFields.map((f) => `${f}=${encodeURIComponent(record[f])}`).join('&');

  // Arrow functions: (param) => body is ES6 shorthand for function(param) { return body; }
  // Combines multiple params into one query string, filtering out empty values.
  const joinParams = (...parts) => parts.filter(Boolean).join('&');
  // Builds full URL: add params as query string if present, otherwise just base URL + path.
  const buildRequestUrl = (params) => params ? `${BASE_URL}${apiPath}?${params}` : `${BASE_URL}${apiPath}`;

  switch (method) {
    case 'POST':
      return buildRequestUrl(isSequenced ? dataParams : joinParams(pkParams, dataParams));
    case 'GET':
      return buildRequestUrl(pkParams);
    case 'PUT':
      return buildRequestUrl(joinParams(pkParams, dataParams));
    case 'DELETE':
      return buildRequestUrl(pkParams);
    default:
      throw new Error(`Unsupported HTTP method: ${method}. Only POST, GET, PUT, and DELETE are supported.`);
  }
}

/**
 * Executes one endpoint HTTP operation and validates status and result.
 * @param {string} method - HTTP method: POST, GET, PUT, or DELETE.
 * @param {{[key: string]: unknown}} record - Record containing primary key and supporting fields.
 * @param {string} phase - Execution phase: 'setup', 'default', or 'teardown'.
 * @param {object} options - Options object with resourceName, resourceConfig, isValidResponseFn, apiPath.
 * @returns {{ res: import('k6/http').RefinedResponse<'text'>, body: object|null }} HTTP response and parsed body.
 */
export function callRemoteEndpoint(method, record, phase, options) {
  const { resourceName, resourceConfig, isValidResponseFn, apiPath } = options;
  const profile = getProfile(); // Obtain profile dynamically at call time
  const isTeardownPhase = phase === 'teardown';

  // Enforce per-Virtual User authentication only during 'default' phase (test execution).
  //
  // k6 execution model:
  // - setup(): Runs once globally BEFORE any VUs are spawned. No __VU context available.
  //   Used to create shared test data (via anonymous/system context).
  // - default(): Runs per-VU repeatedly during the test. __VU is available and stable per-VU.
  //   Used for actual test traffic, where each VU has its own authenticated session.
  // - teardown(): Runs once globally AFTER all VUs complete. No __VU context available.
  //   Used for cleanup, runs with anonymous/system context.
  //
  // Per-VU authentication (ensureAuthenticationIfRequired) requires __VU to build deterministic
  // usernames. Attempting to auth in setup/teardown would crash because __VU is undefined outside VU context.
  // Therefore, auth enforcement is gated to 'default' phase only.
  if (phase === 'default') {
    ensureAuthenticationIfRequired();
  }

  const headers = method === 'GET' ? JSON_ACCEPT_HEADERS : JSON_HEADERS;
  const requestName = `${method} ${apiPath}`;
  const url = buildUrl(method, record, resourceConfig, apiPath);
  // Regarding the structure of the tags object below:
  // 'name' is the k6 URL grouping override - it replaces the raw request URL (including
  // dynamic query parameters) as the metric series key. Must be listed first and must
  // remain a stable, parameter-free label so all requests to the same logical endpoint
  // collapse into a single metric series rather than producing unbounded cardinality.
  const res = http.request(method, url, null, {
    headers,
    tags: {
        name: requestName,
        apiType: 'crud',
        resource: resourceName,
        profile,
    },
  });
  const body = parseJsonBody(res);
  recordAblDuration(res, 'crud');
  const statusOk = isTeardownPhase ? [200, 201, 404].includes(res.status) : [200, 201].includes(res.status);
  const contractOk = isValidResponseFn(method, record, phase, body, options);
  const noServerErrors = !hasServerErrorResponse(body);

  const statusCheckName = labelCheckName(phase, `${method} response status valid (OK)`);
  const contractCheckName = labelCheckName(phase, `${method} result/data contract valid`);
  const noErrorCheckName = labelCheckName(phase, `${method} no error responses present`);

  const passed = check(res, {
    [statusCheckName]: () => statusOk,
    [contractCheckName]: () => contractOk,
    [noErrorCheckName]: () => noServerErrors,
  });

  if (!passed) {
    const allowedResultSet = expectedResults(method, phase);
    const failedChecks = [
      statusOk ? null : statusCheckName,
      contractOk ? null : contractCheckName,
      noServerErrors ? null : noErrorCheckName,
    ].filter(Boolean);
    const pkPairs = resourceConfig.pkFields.map(f => `${f.name}=${record?.[f.name] ?? 'n/a'}`).join(', ');

    captureFailureContext({
      failureType: 'crud_check_failure',
      failedChecks,
      response: res,
      metadata: {
        resourceName,
        phase,
        profile,
        pk: pkPairs,
        expectedResult: allowedResultSet.join('|'),
      },
    });

    if (options.canRetry && res.status === 0) {
      return { res, body };
    }

    fail(buildFailMessage(method, resourceName, pkPairs, res, allowedResultSet, body));
  }

  res.body = null; // Clear the body within the response as we already parsed this into a new variable.
  return { res, body };
}

/**
 * Validates response contract against API result/data expectations.
 * @param {string} method - HTTP method: POST, GET, PUT, or DELETE.
 * @param {{[key: string]: unknown}} record - Request record.
 * @param {string} phase - Execution phase.
 * @param {object|null} body - Parsed JSON body.
 * @param {object} options - Options object containing:
 *   @param {object} options.resourceConfig - Resource registry entry with pkFields, data, sequenced.
 *   @param {Function} [options.pkFieldValidator] - Custom validator for primary key fields.
 *   @param {Function} [options.dataFieldValidator] - Custom validator for data fields.
 *   @param {Function} [options.exactMatchValidator] - Custom validator for exact data matching.
 *   @param {Function} [options.customResponseValidator] - Custom validator for entire response.
 * @returns {boolean} True when response body is valid for the operation.
 */
export function validateResponseContract(method, record, phase, body, options) {
  if (!body) {
    return false;
  }

  // Pull specific properties out of the options object into separate variables.
  const {
    resourceConfig,
    pkFieldValidator,
    dataFieldValidator,
    exactMatchValidator,
    customResponseValidator,
  } = options;

  const profile = getProfile();
  const pkFields = resourceConfig?.pkFields || [];
  const dataFields = resourceConfig?.data || [];

  const validatePkField = pkFieldValidator || ((fieldName, value) => {
    return typeof value === 'number' && Number.isInteger(value) && value > 0;
  });
  const validateDataField = dataFieldValidator || ((fieldName, value) => {
    return typeof value === 'string';
  });

  // If given a callback to enforce exact field matching, call it or default to PUT only (intended changes must match the result).
  const requireExactDataMatch = exactMatchValidator
                              ? exactMatchValidator(method, phase, profile)
                              : method === 'PUT';

  const allowed = expectedResults(method, phase);
  if (typeof body.result !== 'string' || !allowed.includes(body.result)) {
    return false;
  }

  const createResults = expectedResults('POST', 'default');
  const readUpdateDefaultResults = expectedResults('GET', 'default');
  const readUpdateTeardownOnlyResults = expectedResults(method, 'teardown').filter((result) => {
    return !readUpdateDefaultResults.includes(result);
  });

  const expectsDataPayload =
    (method === 'POST' && createResults.includes(body.result))
    || ((method === 'GET' || method === 'PUT') && readUpdateDefaultResults.includes(body.result));

  const mustOmitDataPayload =
    (method === 'DELETE' && expectedResults('DELETE', phase).includes(body.result))
    || ((method === 'GET' || method === 'PUT') && readUpdateTeardownOnlyResults.includes(body.result));

  if (expectsDataPayload) {
    if (!body.data || typeof body.data !== 'object') {
      return false;
    }

    const allPkValid = pkFields.every((f) => validatePkField(f.name, body.data[f.name], { method, phase, body, record, profile }));
    if (!allPkValid) {
      return false;
    }

    if (method !== 'POST' && pkFields.some((f) => body.data[f.name] !== record[f.name])) {
      return false;
    }

    const allDataFieldsValid = dataFields.every((f) => validateDataField(f, body.data[f], { method, phase, body, record, profile }));
    if (!allDataFieldsValid) {
      return false;
    }

    if (requireExactDataMatch) {
      const allDataFieldsMatch = dataFields.every((f) => body.data[f] === record[f]);
      if (!allDataFieldsMatch) {
        return false;
      }
    }
  }

  if (mustOmitDataPayload) {
    if (Object.prototype.hasOwnProperty.call(body, 'data')) {
      return false;
    }
  }

  if (customResponseValidator) {
    return customResponseValidator(method, record, phase, body, options);
  }

  return true;
}

/**
 * Creates one record and captures any server-generated key fields for sequenced resources.
 * @param {{[key: string]: unknown}} payload - Create payload.
 * @param {object} options - Options object with resourceName, resourceConfig, isValidResponseFn, apiPath.
 * @returns {{[key: string]: unknown}} Created record with any new key fields merged into the payload.
 */
export function createRecordAndCaptureKey(payload, options) {
  const { resourceName, resourceConfig } = options;
  const MAX_SETUP_POST_RETRIES = 3;

  let body = null;
  let currentPayload = payload;
  for (let attempt = 1; attempt <= MAX_SETUP_POST_RETRIES; attempt++) {
    /**
     * Retries up to MAX_SETUP_POST_RETRIES times on network-level timeouts (status 0, k6 errorCode 1050),
     * where the server may have processed the request but the response was lost in transit.
     * Any non-timeout failure (4xx, 5xx) aborts immediately without retrying.
     */
    const isLastAttempt = attempt === MAX_SETUP_POST_RETRIES;
    const result = callRemoteEndpoint('POST', currentPayload, 'setup', { ...options, canRetry: !isLastAttempt });
    if (result.res.status !== 0) {
      body = result.body;
      break;
    }

    if (!resourceConfig.sequenced) {
      /**
       * Non-sequenced: the PK is caller-supplied, so verify via GET whether the server
       * committed the timed-out request. A 200 means it was created; return the payload
       * as-is. Anything else means it wasn't committed; loop and retry POST.
       */
      const verifyUrl = buildUrl('GET', currentPayload, resourceConfig, options.apiPath);
      const verifyRes = http.request('GET', verifyUrl, null, { headers: JSON_ACCEPT_HEADERS });
      verifyRes.body = null; // Only status is needed for commit verification - release the body immediately.
      if (verifyRes.status === 200) {
        return currentPayload;
      }
    } else {
      /**
       * Sequenced: the server assigns the PK, so re-sending the same data fields can
       * trigger a uniqueness constraint 500 if the first attempt was committed. Vary all
       * string data fields with a retry suffix so each attempt produces a distinct record.
       */
      const retryPayload = { ...currentPayload };
      resourceConfig.data.forEach((f) => {
        if (typeof retryPayload[f] === 'string') {
          retryPayload[f] = `${retryPayload[f]}-r${attempt}`;
        }
      });
      currentPayload = retryPayload;
    }
  }

  if (!resourceConfig.sequenced) {
    return currentPayload;
  }

  const validCreateResult = body && expectedResults('POST', 'default').includes(body.result);
  if (!validCreateResult || !body.data || typeof body.data !== 'object') {
    fail(`[fail] POST ${resourceName} create did not return an expected response body. bodySummary=${summarizeResponseBody(body)}`);
  }

  // Extract only the PK fields that were server-assigned (changed from request).
  // Each filter step uses arrow function (f) => condition, which means "for each field f, keep if condition is true".
  const newPkFields = Object.fromEntries(
    resourceConfig.pkFields
      .filter((f) => Object.prototype.hasOwnProperty.call(body.data, f.name))  // Field exists in response
      .filter((f) => body.data[f.name] !== null && body.data[f.name] !== undefined) // Field has a value
      .filter((f) => currentPayload[f.name] !== body.data[f.name])                  // Field value changed from request
      .map((f) => [f.name, body.data[f.name]]),                                     // Convert to [fieldName, fieldValue] pairs
  );

  if (Object.keys(newPkFields).length === 0) {
    fail(`[fail] POST ${resourceName} create did not return any new sequenced key fields. expectedOneOf=${resourceConfig.pkFields.map(f => f.name).join('|')}, bodySummary=${summarizeResponseBody(body)}`);
  }

  body = null; // PK extraction and error check complete - release the full response body before returning.

  return {
    ...currentPayload,
    ...newPkFields,
  };
}

/**
 * Selects a record index from the seeded pool using VU and iteration offsets.
 * Each VU starts at a different stride position and advances each iteration,
 * distributing access across the pool without per-VU random seed correlation.
 * Minimizes lock contention compared to Math.random() when VUs share the same pool.
 * @param {number} poolSize - Number of records in the pool.
 * @returns {number} Zero-based record index in [0, poolSize).
 */
export function pickRecordIndex(poolSize) {
  return (__VU - 1 + __ITER) % poolSize;
}

/**
 * Returns a random integer in the inclusive range [1, max].
 * Used to select a pre-existing record from the database pool when CREATE_SEED_RECORDS is false.
 * @param {number} [max=SEED_RECORD_MAX] - Upper bound of the range (inclusive).
 * @returns {number} Random integer in [1, max].
 */
export function randomPoolValue(max = SEED_RECORD_MAX) {
  return Math.floor(Math.random() * max) + 1;
}

/**
 * Constructs a natural (non-sequenced) primary key string in the form OELS-<FIELDNAME>-<VALUE>.
 * Used when CREATE_SEED_RECORDS is false to reference pre-existing records by their known key pattern.
 *
 * The value is zero-padded to 6 digits when <= 999999 (e.g. 1 → "000001", 999999 → "999999").
 * Values above 999999 are used as-is with no padding or commas (e.g. 1000000 → "1000000").
 *
 * This matches the ABL genFieldData() padding convention in GenSportsData.p.
 *
 * @param {string} fieldName - The primary key field name (e.g. 'SalesRep', 'DeptCode').
 * @param {number|string} value - The record identifier, typically from randomPoolValue().
 * @returns {string} Natural key string, e.g. "OELS-SALESREP-000042".
 */
export function buildNaturalKey(fieldName, value) {
  const n = Number(value);
  const padded = n <= 999999 ? String(n).padStart(6, '0') : String(n);
  return `OELS-${fieldName.toUpperCase()}-${padded}`;
}

/**
 * Issues an unauthenticated GET for the resource record at SEED_RECORD_MAX.
 * Constructs the max PK identically to resolveRecord() and hard-fails if the
 * server does not return HTTP 200, indicating the pool range exceeds actual data.
 * Intended for use in setup() pre-flight validation only.
 * @param {string} resourceName - Resource name (lowercase, e.g. 'department').
 */
export function probeResourceAtMax(resourceName) {
  const resourceConfig = getResourceConfig(resourceName);
  const apiPath        = `${API_PREFIX}${DATA_SERVICE}/${resourceName}`;
  const pkRecord       = {};

  for (const field of resourceConfig.pkFields) {
    if (resourceConfig.sequenced || field.type === 'integer') {
      pkRecord[field.name] = SEED_RECORD_MAX;
    } else if (field.type === 'string') {
      pkRecord[field.name] = buildNaturalKey(field.name, SEED_RECORD_MAX);
    } else if (field.type === 'date') {
      pkRecord[field.name] = new Date(DATE_EPOCH_MS + SEED_RECORD_MAX * 60000)
                               .toISOString().substring(0, 10);
    }
  }

  const url = buildUrl('GET', pkRecord, resourceConfig, apiPath);
  const PROBE_MAX_ATTEMPTS = 2;
  const PROBE_RETRY_DELAY  = 1; // seconds between attempts
  let lastStatus = 0;

  for (let attempt = 1; attempt <= PROBE_MAX_ATTEMPTS; attempt++) {
    const res = http.get(url, { headers: JSON_ACCEPT_HEADERS });
    if (res.status === 200) return;
    lastStatus = res.status;
    if (attempt < PROBE_MAX_ATTEMPTS) {
      sleep(PROBE_RETRY_DELAY);
    }
  }

  fail(
    `[setup] Pool probe failed for '${resourceName}' after ${PROBE_MAX_ATTEMPTS} attempts: ` +
    `GET ${url} returned HTTP ${lastStatus}. ` +
    `SEED_RECORD_MAX=${SEED_RECORD_MAX} may exceed the actual record count for this table.`
  );
}

/**
 * Resolves a single working record for use in default() VU iterations.
 *
 * When CREATE_SEED_RECORDS is true, a record was created in setup() and stored in data.records.
 * This path picks one entry from that local pool using VU/iteration-based stride selection.
 *
 * When CREATE_SEED_RECORDS is false, data.records is empty. A synthetic record is constructed
 * on-the-fly using the resource's PK shape as declared in each pkField descriptor:
 *   - sequenced resource: all PK fields use randomPoolValue() → integer key (server-assigned).
 *   - type 'integer': randomPoolValue() → integer (caller-supplied numeric FK or line number).
 *   - type 'string':  buildNaturalKey() → "OELS-<FIELD_UPPERCASE>-<PADDED>" (caller-supplied character key).
 *   - type 'date':    DATE_EPOCH_MS plus recordId minutes → YYYY-MM-DD string sent to the API.
 *
 * The returned object contains only the PK fields. Data fields (Name, etc.) are not populated
 * since they are not needed for GET/PUT/DELETE operations against pre-existing records.
 *
 * @param {{records?: Array<{[key: string]: unknown}>}} data - Setup data passed to default().
 * @param {object} options - CALL_OPTIONS object with resourceConfig populated.
 * @returns {{[key: string]: unknown}} A record object with PK fields set.
 */
export function resolveRecord(data, options) {
  const { resourceConfig } = options;

  // Iteration gate: session expiry is checked once, here, before any work begins.
  // If expired, the invalidation/logout cycle runs and this iteration is skipped.
  // The VU will still be expired on the next iteration and will be caught again.
  // This intentionally does NOT fire mid-iteration - a VU that becomes expired during
  // an in-progress GET or PUT is allowed to finish that iteration normally.
  if (handleSessionDurationExpiry()) return null;

  if (shouldCreateSeedRecords()) {
    // Records were created in setup() and stored in data.records - pick one by VU/iteration stride.
    const seededRecords = Array.isArray(data.records) ? data.records : Object.values(data.records || {});
    return { ...seededRecords[pickRecordIndex(seededRecords.length)] };
  }

  // Construct the PK from the database pool range [1, SEED_RECORD_MAX],
  // then GET the actual record from the server to confirm it exists and retrieve all field values.
  // This ensures PUT operations have the full field set and the record is genuinely present.
  const pkRecord = {};
  const poolValue = randomPoolValue();
  for (const field of resourceConfig.pkFields) {
    if (resourceConfig.sequenced || field.type === 'integer') {
      pkRecord[field.name] = poolValue;
    } else if (field.type === 'string') {
      pkRecord[field.name] = buildNaturalKey(field.name, poolValue);
    } else if (field.type === 'date') {
      // epoch + (recordId * 60000 ms) = recordId minutes after epoch, formatted as YYYY-MM-DD for the API.
      pkRecord[field.name] = new Date(DATE_EPOCH_MS + poolValue * 60000).toISOString().substring(0, 10);
    } else {
      fail(`[fail] resolveRecord: field '${field.name}' has unrecognized type '${field.type}'.`);
    }
  }

  const result = callRemoteEndpoint('GET', pkRecord, 'default', options);
  if (!result) return null; // session-expiry cycle; caller must end iteration
  return result.body.data;
}
