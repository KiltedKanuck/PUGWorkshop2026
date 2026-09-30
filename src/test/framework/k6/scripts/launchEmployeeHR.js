/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 *
 * k6 scenario launcher - Employee & HR group (6 CRUD tests run simultaneously).
 *
 * FK-safe setup order: department → employee → benefits / family / timesheet / vacation
 * Teardown reverses: children first, then employee, then department.
 *
 * Usage:
 *   k6 run --env CONFIG_FILE=configs/smoke-local.json    launchEmployeeHR.js
 *   k6 run --env CONFIG_FILE=configs/load-baseline.json  launchEmployeeHR.js
 *   k6 run                                               launchEmployeeHR.js  (smoke defaults)
 */

import { buildLauncherScenarioFromProfile, buildTopLevelProfileOptions } from '../common/scenarios.js';
import { loadConfig, logResolvedConfig } from '../common/configLoader.js';
import { setProfile, applyEnvConfig }    from '../common/config.js';
import { applyAuthConfig }               from '../common/auth.js';
import { applyDiagnosticsConfig }        from '../common/diagnostics.js';
import { createHandleSummary }           from '../common/summary.js';

export const handleSummary = createHandleSummary('launchEmployeeHR');

import { default as departmentTest, setup as setupDepartment, teardown as teardownDepartment } from './crud/department.js';
import { default as employeeTest,   setup as setupEmployee,   teardown as teardownEmployee   } from './crud/employee.js';
import { default as benefitsTest,   setup as setupBenefits,   teardown as teardownBenefits   } from './crud/benefits.js';
import { default as familyTest,     setup as setupFamily,     teardown as teardownFamily     } from './crud/family.js';
import { default as timesheetTest,  setup as setupTimesheet,  teardown as teardownTimesheet  } from './crud/timesheet.js';
import { default as vacationTest,   setup as setupVacation,   teardown as teardownVacation   } from './crud/vacation.js';

// ---------------------------------------------------------------------------
// Config loading - must happen before export const options is evaluated.
// ---------------------------------------------------------------------------
const _rawConfig = __ENV.CONFIG_FILE ? open(__ENV.CONFIG_FILE) : null;
let _baseConfig = null;
if (_rawConfig) {
  try {
    const _peek = JSON.parse(_rawConfig);
    if (_peek.extends) { _baseConfig = open(_peek.extends); }
  } catch (_) {}
}
const _cfg = loadConfig(_rawConfig, _baseConfig);

setProfile(_cfg.run.profile);
applyEnvConfig(_cfg.env);
applyAuthConfig(_cfg.env);
applyDiagnosticsConfig(_cfg.env);

const scenario = buildLauncherScenarioFromProfile();
const topLevelOptions = buildTopLevelProfileOptions();

export const options = {
  ...topLevelOptions,
  setupTimeout:    _cfg.options.setupTimeout    || '20m',
  teardownTimeout: _cfg.options.teardownTimeout || '20m',
  tags: { launcher: 'launchEmployeeHR', ...(_cfg.options.tags || {}) },
  scenarios: {
    Department: { ...scenario, exec: 'Department' },
    Employee:   { ...scenario, exec: 'Employee'   },
    Benefits:   { ...scenario, exec: 'Benefits'   },
    Family:     { ...scenario, exec: 'Family'     },
    Timesheet:  { ...scenario, exec: 'Timesheet'  },
    Vacation:   { ...scenario, exec: 'Vacation'   },
  },
  thresholds: {
    http_req_failed: ['rate<0.05'],
    checks:          ['rate>=0.95'],
  },
};
logResolvedConfig(_cfg, options);

/**
 * Combined setup - seeds all Employee & HR data in FK-safe order.
 * Returns namespaced data so each scenario receives only its own slice.
 * @returns {{department: object, employee: object, benefits: object, family: object, timesheet: object, vacation: object}}
 */
export function setup() {
  const dependencyRegistry = {};
  const setupContext = { dependencyRegistry };

  const department = setupDepartment(setupContext);
  dependencyRegistry.department = department;
  const employee = setupEmployee(setupContext);
  dependencyRegistry.employee = employee;

  return {
    department,
    employee,
    benefits:   setupBenefits(setupContext),
    family:     setupFamily(setupContext),
    timesheet:  setupTimesheet(setupContext),
    vacation:   setupVacation(setupContext),
  };
}

// Wrapper scenario functions - each receives the full combined data object
// and passes only its own namespace slice to the underlying test default.
export function Department(data) { departmentTest(data.department); }
export function Employee(data)   { employeeTest(data.employee);     }
export function Benefits(data)   { benefitsTest(data.benefits);     }
export function Family(data)     { familyTest(data.family);         }
export function Timesheet(data)  { timesheetTest(data.timesheet);   }
export function Vacation(data)   { vacationTest(data.vacation);     }

/**
 * Combined teardown - removes seeded data in reverse FK order.
 * Child records deleted before the employee parent, employee before department.
 * @param {{department: object, employee: object, benefits: object, family: object, timesheet: object, vacation: object}} data
 */
export function teardown(data) {
  teardownBenefits(data.benefits);
  teardownFamily(data.family);
  teardownTimesheet(data.timesheet);
  teardownVacation(data.vacation);
  teardownEmployee(data.employee);
  teardownDepartment(data.department);
}