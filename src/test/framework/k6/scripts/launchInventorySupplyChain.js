/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 *
 * k6 scenario launcher - Inventory & Supply Chain group (8 CRUD tests run simultaneously).
 *
 * FK-safe setup order:
 *   bin, warehouse, inventorytrans (independent)
 *   item, supplier, purchaseorder  (independent parents)
 *   → supplieritemxref             (depends on item + supplier)
 *   → poline                       (depends on purchaseorder)
 * Teardown reverses the order.
 *
 * Usage:
 *   k6 run --env CONFIG_FILE=configs/smoke-local.json    launchInventorySupplyChain.js
 *   k6 run --env CONFIG_FILE=configs/load-baseline.json  launchInventorySupplyChain.js
 *   k6 run                                               launchInventorySupplyChain.js  (smoke defaults)
 */

import { buildLauncherScenarioFromProfile, buildTopLevelProfileOptions } from '../common/scenarios.js';
import { loadConfig, logResolvedConfig } from '../common/configLoader.js';
import { setProfile, applyEnvConfig }    from '../common/config.js';
import { applyAuthConfig }               from '../common/auth.js';
import { applyDiagnosticsConfig }        from '../common/diagnostics.js';
import { createHandleSummary }           from '../common/summary.js';

export const handleSummary = createHandleSummary('launchInventorySupplyChain');

import { default as itemTest,            setup as setupItem,            teardown as teardownItem             } from './crud/item.js';
import { default as binTest,             setup as setupBin,             teardown as teardownBin              } from './crud/bin.js';
import { default as warehouseTest,       setup as setupWarehouse,       teardown as teardownWarehouse        } from './crud/warehouse.js';
import { default as inventorytransTest,  setup as setupInventorytrans,  teardown as teardownInventorytrans   } from './crud/inventorytrans.js';
import { default as supplierTest,        setup as setupSupplier,        teardown as teardownSupplier         } from './crud/supplier.js';
import { default as supplieritemxrefTest,setup as setupSupplieritemxref,teardown as teardownSupplieritemxref } from './crud/supplieritemxref.js';
import { default as purchaseorderTest,   setup as setupPurchaseorder,   teardown as teardownPurchaseorder    } from './crud/purchaseorder.js';
import { default as polineTest,          setup as setupPoline,          teardown as teardownPoline           } from './crud/poline.js';

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
  tags: { launcher: 'launchInventorySupplyChain', ...(_cfg.options.tags || {}) },
  scenarios: {
    Item:             { ...scenario, exec: 'Item'             },
    Bin:              { ...scenario, exec: 'Bin'              },
    Warehouse:        { ...scenario, exec: 'Warehouse'        },
    Inventorytrans:   { ...scenario, exec: 'Inventorytrans'   },
    Supplier:         { ...scenario, exec: 'Supplier'         },
    Supplieritemxref: { ...scenario, exec: 'Supplieritemxref' },
    Purchaseorder:    { ...scenario, exec: 'Purchaseorder'    },
    Poline:           { ...scenario, exec: 'Poline'           },
  },
  thresholds: {
    http_req_failed: ['rate<0.05'],
    checks:          ['rate>=0.95'],
  },
};
logResolvedConfig(_cfg, options);

/**
 * @returns {object} Namespaced setup data keyed by test name.
 */
export function setup() {
  const dependencyRegistry = {};
  const setupContext = { dependencyRegistry };

  const item = setupItem(setupContext);
  dependencyRegistry.item = item;
  const warehouse = setupWarehouse(setupContext);
  dependencyRegistry.warehouse = warehouse;
  const supplier = setupSupplier(setupContext);
  dependencyRegistry.supplier = supplier;
  const purchaseorder = setupPurchaseorder(setupContext);
  dependencyRegistry.purchaseorder = purchaseorder;

  const bin = setupBin(setupContext);
  const inventorytrans = setupInventorytrans(setupContext);
  const supplieritemxref = setupSupplieritemxref(setupContext);
  const poline = setupPoline(setupContext);
  return { item, bin, warehouse, inventorytrans, supplier, supplieritemxref, purchaseorder, poline };
}

// Wrapper scenario functions - each receives the full combined data object
// and passes only its own namespace slice to the underlying test default.
export function Item(data)             { itemTest(data.item);                         }
export function Bin(data)              { binTest(data.bin);                           }
export function Warehouse(data)        { warehouseTest(data.warehouse);               }
export function Inventorytrans(data)   { inventorytransTest(data.inventorytrans);     }
export function Supplier(data)         { supplierTest(data.supplier);                 }
export function Supplieritemxref(data) { supplieritemxrefTest(data.supplieritemxref); }
export function Purchaseorder(data)    { purchaseorderTest(data.purchaseorder);       }
export function Poline(data)           { polineTest(data.poline);                     }

/**
 * Combined teardown - removes seeded data in reverse FK order.
 * supplieritemxref deleted before item/supplier; poline before purchaseorder.
 * @param {object} data Combined setup data.
 */
export function teardown(data) {
  teardownSupplieritemxref(data.supplieritemxref);
  teardownPoline(data.poline);
  teardownItem(data.item);
  teardownSupplier(data.supplier);
  teardownPurchaseorder(data.purchaseorder);
  teardownBin(data.bin);
  teardownWarehouse(data.warehouse);
  teardownInventorytrans(data.inventorytrans);
}