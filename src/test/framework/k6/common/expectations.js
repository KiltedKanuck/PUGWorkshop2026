/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 */

/**
 * Returns valid result strings for a CRUD method based on standard responses.
 * These are intended to apply to the body "result" property.
 * @param {'POST'|'GET'|'PUT'|'DELETE'} method - HTTP method.
 * @param {'default'|'teardown'} phase - Execution phase.
 *  default: business flow; missing records are failures.
 *  teardown: idempotent cleanup; missing records are acceptable.
 * @returns {string[]} Allowed result values.
 */
export function expectedResults(method, phase) {
  const allowMissingRecord = phase === 'teardown';
  switch (method) {
    case 'DELETE':
      return allowMissingRecord ? ['Record Deleted', 'Record Unavailable', 'Record Locked'] : ['Record Deleted'];
    case 'POST':
      return ['Record Created', 'Record Exists'];
    case 'GET':
    case 'PUT':
      return allowMissingRecord ? ['Record Found', 'Record Unavailable', 'Record Locked'] : ['Record Found'];
    default:
      throw new Error(`Unsupported HTTP method: ${method}`);
  }
}
