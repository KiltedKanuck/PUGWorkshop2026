/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 *
 * k6 unified composite scenario launcher.
 *
 * Runs both CRUD and NOOP (objects service) operations through a SINGLE virtual
 * user pool controlled by the active PROFILE. Each VU authenticates once per
 * session and then randomly dispatches across any available operations for the
 * duration of the test.
 *
 * This replaces the parallel multi-scenario approach in launchMultiScenario.js with
 * a single controllable pool, enabling reliable A-B testing, capacity-aligned
 * concurrency, and realistic mixed workload distribution across database tables.
 *
 * See MULTI_SCENARIO.md for the design rationale and sizing guidelines.
 *
 * Includes:
 * - CRUD groups: Employee & HR, Customer & Sales, Inventory & Supply Chain, System & Configuration
 * - NOOP (objects service) tests: Math operations, String operations, TempTable operations
 * - Anomaly tests: simulate (codeBusy), leak (buffer/handle/memptr/object), disrupt (disconnect/quit/stop),
 *                  and files (osCommandData, inputThroughData) — all disabled by default (weight 0.0)
 *
 * Excludes:
 * - Procedures service tests (currently server-blocked: HTTP 500 / ABL error 5425)
 * - TemptableAddRecords / TemptableDeleteTable (server-side ABL error 3135)
 *
 * Usage:
 *   k6 run --env CONFIG_FILE=configs/load-baseline.json launchUnifiedScenario.js
 *   k6 run --env CONFIG_FILE=configs/chaos-60m.json     launchUnifiedScenario.js
 *   k6 run                                              launchUnifiedScenario.js  (smoke defaults)
 */

import { fail }                                 from 'k6';
import { loadConfig, logResolvedConfig }        from '../common/configLoader.js';
import { setProfile, applyEnvConfig, CRUD_WEIGHT, NOOP_WEIGHT, ANOMALY_DISRUPT_WEIGHT, ANOMALY_FILES_WEIGHT, ANOMALY_LEAK_WEIGHT, ANOMALY_SIMULATE_WEIGHT } from '../common/config.js';
import { probeResourceAtMax }                   from '../common/crud.js';
import { applyAuthConfig }                      from '../common/auth.js';
import { applyDiagnosticsConfig }               from '../common/diagnostics.js';
import { buildScenarioFromProfile }             from '../common/scenarios.js';
import { createHandleSummary }                  from '../common/summary.js';

export const handleSummary = createHandleSummary('launchUnifiedScenario');

/**
 * In order to reduce memory consumption during high-VU testing, certain operations have been
 * commented out. k6's ramping-vus executor pre-allocates all VU runtimes before the test starts,
 * and each VU clones the full module graph. This would occur before the first HTTP request fires.
 *
 * Each clone would contain:
 *   - Compiled bytecode      - the parsed, executable form of every function in every imported module
 *   - Closures               - functions that "remember" variables from the scope where they were
 *                              defined (e.g. a helper that captured BASE_URL at import time carries
 *                              that value baked in, not looked up at call time)
 *   - Module-level state     - every top-level const/let evaluated when the module first loads
 *                              (e.g. BASE_URL, the resource registry object, config constants)
 *   - Dispatch arrays        - the CRUD_OPERATIONS and NOOP_OPERATIONS arrays and their closures,
 *                              one independent copy per VU so iterations cannot share or corrupt state
 *
 * Example: Using 800 VUs and 46 modules, that is 36,800 module instantiations created.
 *
 * tl;dr: Fewer active imports means less memory per VU, raising the practical VU ceiling before
 * a possible OOM on a memory-constrained host executing the k6 test. This focuses on audited tables.
 */

// CRUD test functions
import { default as departmentTest    } from './crud/department.js';
import { default as employeeTest      } from './crud/employee.js';
import { default as benefitsTest      } from './crud/benefits.js';
import { default as familyTest        } from './crud/family.js';
import { default as timesheetTest     } from './crud/timesheet.js';
import { default as vacationTest      } from './crud/vacation.js';
import { default as customerTest      } from './crud/customer.js';
import { default as salesrepTest      } from './crud/salesrep.js';
import { default as orderTest         } from './crud/order.js';
import { default as invoiceTest       } from './crud/invoice.js';
import { default as feedbackTest      } from './crud/feedback.js';
import { default as refcallTest       } from './crud/refcall.js';
import { default as itemTest          } from './crud/item.js';
import { default as binTest           } from './crud/bin.js';
import { default as warehouseTest     } from './crud/warehouse.js';
import { default as supplierTest      } from './crud/supplier.js';
import { default as purchaseorderTest } from './crud/purchaseorder.js';

// NOOP (objects service) test functions - no setup/teardown required
import { default as objFloatAddition }          from './objects/floataddition.js';
import { default as objFloatDivision }          from './objects/floatdivision.js';
import { default as objFloatMultiplication }    from './objects/floatmultiplication.js';
import { default as objFloatSubtraction }       from './objects/floatsubtraction.js';
import { default as objIntegerAddition }        from './objects/integeraddition.js';
import { default as objIntegerDivision }        from './objects/integerdivision.js';
import { default as objIntegerMultiplication }  from './objects/integermultiplication.js';
import { default as objIntegerSubtraction }     from './objects/integersubtraction.js';
import { default as objLongAddition }           from './objects/longaddition.js';
import { default as objLongDivision }           from './objects/longdivision.js';
import { default as objLongMultiplication }     from './objects/longmultiplication.js';
import { default as objLongSubtraction }        from './objects/longsubtraction.js';
import { default as objStringLongWhatLetter }   from './objects/stringlongwhatletter.js';
import { default as objStringLongWhatWord }     from './objects/stringlongwhatword.js';
import { default as objStringShortFindIn }      from './objects/stringshortfindin.js';
import { default as objStringShortHelloJoin }   from './objects/stringshorthellojoin.js';
import { default as objStringShortWhatLetter }  from './objects/stringshortwhatletter.js';
import { default as objStringShortWhatWord }    from './objects/stringshortwhatword.js';

// Anomaly test functions - disruptive/unusual server-side behavior
// Grouped by sub-type: simulate (codeBusy), leak (buffer/handle/memptr/object),
//                      disrupt (disconnect/quit/stop), files (osCommandData, inputThroughData).
// NOTE: Enabling ANOMALY_DISRUPT_WEIGHT > 0 includes codeQuit (HTTP 500) and codeStop (HTTP 408),
// which return non-2xx by design. Remove the checks threshold from your config when using
// ANOMALY_DISRUPT_WEIGHT > 0, or check failures will be reported for those operations.
import { default as anomalyCodeBusy }      from './anomaly/codeBusy.js';
import { default as anomalyDbDisconnect }  from './anomaly/dbDisconnect.js';
import { default as anomalyCodeQuit }      from './anomaly/codeQuit.js';
import { default as anomalyCodeStop }      from './anomaly/codeStop.js';
import { default as anomalyLeakBuffer }    from './anomaly/leakBuffer.js';
import { default as anomalyLeakHandle }    from './anomaly/leakHandle.js';
import { default as anomalyLeakMemptr }    from './anomaly/leakMemptr.js';
import { default as anomalyLeakObject }    from './anomaly/leakObject.js';
import { default as anomalyOsCommandData } from './anomaly/osCommandData.js';
import { default as anomalyInputThroughData } from './anomaly/inputThroughData.js';

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

const _profileOptions = buildScenarioFromProfile(_cfg.options.thresholds);
export const options = {
  ..._profileOptions,
  tags: {
    ..._profileOptions.tags,
    ...(_cfg.options.tags || {}),
    launcher: 'launchUnifiedScenario',
  }
};
logResolvedConfig(_cfg, options);

/*
 * =============================
 * Operation Dispatch Tables
 * =============================
 * Each VU iteration randomly selects one operation from the combined pool.
 * This ensures realistic mixed workload distribution across database tables
 * and avoids artificial single-table saturation.
 */

/**
 * CRUD operation dispatch table.
 * Each entry is a self-contained call requiring no setup data.
 * Records are resolved from the server-generated pool via resolveRecord().
 * @type {Array<function(): void>}
 */
const CRUD_OPERATIONS = [
  () => departmentTest(),
  () => employeeTest(),
  () => benefitsTest(),
  () => familyTest(),
  () => timesheetTest(),
  () => vacationTest(),
  () => customerTest(),
  () => salesrepTest(),
  () => orderTest(),
  () => invoiceTest(),
  () => feedbackTest(),
  () => refcallTest(),
  () => itemTest(),
  () => binTest(),
  () => warehouseTest(),
  () => supplierTest(),
  () => purchaseorderTest(),
];

/**
 * NOOP operation dispatch table.
 * Each entry is a self-contained objects-service call requiring no setup data.
 * Auth is handled internally by each function.
 * @type {Array<function(): void>}
 */
const NOOP_OPERATIONS = [
  () => objFloatAddition(),
  () => objFloatDivision(),
  () => objFloatMultiplication(),
  () => objFloatSubtraction(),
  () => objIntegerAddition(),
  () => objIntegerDivision(),
  () => objIntegerMultiplication(),
  () => objIntegerSubtraction(),
  () => objLongAddition(),
  () => objLongDivision(),
  () => objLongMultiplication(),
  () => objLongSubtraction(),
  () => objStringLongWhatLetter(),
  () => objStringLongWhatWord(),
  () => objStringShortFindIn(),
  () => objStringShortHelloJoin(),
  () => objStringShortWhatLetter(),
  () => objStringShortWhatWord(),
];

/**
 * Anomaly simulate sub-type dispatch table.
 * Long-running operations that consume server CPU/time without side effects.
 * Controlled via ANOMALY_SIMULATE_WEIGHT.
 * @type {Array<function(): void>}
 */
const ANOMALY_SIMULATE_OPERATIONS = [
  () => anomalyCodeBusy(),
];

/**
 * Anomaly leak sub-type dispatch table.
 * Operations that allocate server-side resources without releasing them.
 * Controlled via ANOMALY_LEAK_WEIGHT.
 * @type {Array<function(): void>}
 */
const ANOMALY_LEAK_OPERATIONS = [
  () => anomalyLeakBuffer(),
  () => anomalyLeakHandle(),
  () => anomalyLeakMemptr(),
  () => anomalyLeakObject(),
];

/**
 * Anomaly disrupt sub-type dispatch table.
 * Operations that cause session-level disruption (disconnect, QUIT, STOP).
 * WARNING: codeQuit returns HTTP 500 and codeStop returns HTTP 408 by design.
 * Controlled via ANOMALY_DISRUPT_WEIGHT. Requires removing the checks threshold
 * from your config to avoid false failures.
 * @type {Array<function(): void>}
 */
const ANOMALY_DISRUPT_OPERATIONS = [
  () => anomalyDbDisconnect(),
  () => anomalyCodeQuit(),
  () => anomalyCodeStop(),
];

/**
 * Anomaly files sub-type dispatch table.
 * Operations that fork the session agent process via OS-COMMAND or INPUT-THROUGH,
 * temporarily copying its virtual address space. Useful for measuring OS-level memory impact.
 * Controlled via ANOMALY_FILES_WEIGHT.
 * @type {Array<function(): void>}
 */
const ANOMALY_FILES_OPERATIONS = [
  () => anomalyOsCommandData(),
  () => anomalyInputThroughData(),
];

/**
 * Implement a standard weighted random algorithm.
 * Selects one operation using weighted random selection across all six categories:
 * CRUD, NOOP, anomaly-simulate, anomaly-leak, anomaly-disrupt, and anomaly-files.
 * See: https://dev.to/jacktt/understanding-the-weighted-random-algorithm-581p
 * All six weights must sum to 1.0, or will default to only CRUD operations.
 * @returns {function(): void} The selected operation function.
 */
function pickWeightedOperation() {
  // Pairs each category's configured weight (from the config file) with its operation array.
  const opWeights = [
    { weight: CRUD_WEIGHT,             ops: CRUD_OPERATIONS             },
    { weight: NOOP_WEIGHT,             ops: NOOP_OPERATIONS             },
    { weight: ANOMALY_SIMULATE_WEIGHT, ops: ANOMALY_SIMULATE_OPERATIONS },
    { weight: ANOMALY_LEAK_WEIGHT,     ops: ANOMALY_LEAK_OPERATIONS     },
    { weight: ANOMALY_DISRUPT_WEIGHT,  ops: ANOMALY_DISRUPT_OPERATIONS  },
    { weight: ANOMALY_FILES_WEIGHT,    ops: ANOMALY_FILES_OPERATIONS    },
  ];

  // Step 1: Total up all weights. Should equal 1.0 (100%). configLoader enforces this
  // when a config file is used, but --env WEIGHT flags bypass that check.
  // If the total is not 1.0, the fallback will return a CRUD operation instead.
  let totalWeight = 0;
  for (const entry of opWeights) {
    totalWeight += entry.weight;
  }

  // If totalWeight is not 1.0 then select a CRUD operation at random.
  if (totalWeight !== 1.0) {
    return CRUD_OPERATIONS[Math.floor(Math.random() * CRUD_OPERATIONS.length)];
  }

  // Step 2: Generate a random probability value on the same 0.0-1.0 scale as the weights.
  // Math.random() always returns in this range per the JavaScript spec.
  const probability = Math.random() * totalWeight;

  // Step 3: Walk the table to find which category probability falls in.
  let accumulated = 0;
  let selectedCategory = CRUD_OPERATIONS;
  for (const entry of opWeights) {
    if (entry.weight === 0) continue; // Categories with a weight of 0 are skipped.

    // The weight of each category is accumulated until the value exceeds the generated
    // probability, resulting in that category being selected for this test iteration.
    accumulated += entry.weight;
    if (accumulated >= probability) {
      selectedCategory = entry.ops;
      break;
    }
  }

  // Pick one operation at random from the selected category's array and return it.
  if (selectedCategory !== null) {
    return selectedCategory[Math.floor(Math.random() * selectedCategory.length)];
  }
}

/*
 * =============================
 * k6 Standard Execution Flow
 * =============================
 * 1) setup()    - reserved stub; CRUD operations resolve records from server-generated pool data
 * 2) default()  - each VU randomly selects and executes one operation per iteration
 * 3) teardown() - reserved stub; no cleanup required for pool-based record resolution
 */

/**
 * Validates pre-conditions required for pool-based record resolution, then probes
 * each active CRUD resource to confirm the server has a record at SEED_RECORD_MAX.
 * Hard-fails on any misconfiguration or missing record so VUs are never spawned
 * against an under-populated database.
 */
export function setup() {
  if (__ENV.CREATE_SEED_RECORDS === 'true') {
    fail(
      '[setup] CREATE_SEED_RECORDS=true is incompatible with launchUnifiedScenario. ' +
      'This launcher resolves records from server-generated pool data. ' +
      'Unset CREATE_SEED_RECORDS and re-run.'
    );
  }

  const poolConfigured = __ENV.SEED_RECORD_MAX !== undefined ||
                         (_cfg.env && _cfg.env.SEED_RECORD_MAX !== undefined);
  if (!poolConfigured) {
    fail(
      '[setup] SEED_RECORD_MAX must be explicitly configured via a config file ' +
      '(env.SEED_RECORD_MAX) or --env SEED_RECORD_MAX=<n>. ' +
      'This ensures the pool range matches the actual database record count.'
    );
  }

  /*
   * Pool probe: verify that each CRUD table has a record at the configured maximum
   * pool index. probeResourceAtMax() constructs the max PK, issues an unauthenticated
   * GET, and hard-fails if the response is not HTTP 200.
   */
  const PROBE_RESOURCES = [
    'department', 'employee',  'benefits', 'family',   'timesheet', 'vacation',
    'customer',   'salesrep',  'order',    'invoice',  'feedback',  'refcall',
    'item',       'bin',       'warehouse','supplier', 'purchaseorder',
  ];

  for (const resourceName of PROBE_RESOURCES) {
    probeResourceAtMax(resourceName);
  }
}

/**
 * Runs once per VU iteration.
 * Selects one operation using flat weighted dispatch across CRUD, NOOP, anomaly-simulate,
 * anomaly-leak, anomaly-disrupt, and anomaly-files categories. Auth is handled internally; by default
 * (AUTH_STICKY_SESSIONS=true), the VU's session cookie persists across iterations for
 * realistic user behavior. Pass --env AUTH_STICKY_SESSIONS=false to re-authenticate on
 * each iteration.
 */
export default function runUserFlow() {
  pickWeightedOperation()();
}

/**
 * Reserved for future use. Currently a no-op stub.
 */
export function teardown() {
}
