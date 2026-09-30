/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 *
 * k6 scenario launcher - Customer & Sales group (9 CRUD tests run simultaneously).
 *
 * FK-safe setup order:
 *   salesrep, invoice, feedback (independent)
 *   → customer
 *   → billto, shipto, refcall, order  (depend on customer)
 *   → orderline                       (depends on order)
 * Teardown reverses the order.
 *
 * Usage:
 *   k6 run --env CONFIG_FILE=configs/smoke-local.json    launchCustomerSales.js
 *   k6 run --env CONFIG_FILE=configs/load-baseline.json  launchCustomerSales.js
 *   k6 run                                               launchCustomerSales.js  (smoke defaults)
 */

import { buildLauncherScenarioFromProfile, buildTopLevelProfileOptions } from '../common/scenarios.js';
import { loadConfig, logResolvedConfig } from '../common/configLoader.js';
import { setProfile, applyEnvConfig }    from '../common/config.js';
import { applyAuthConfig }               from '../common/auth.js';
import { applyDiagnosticsConfig }        from '../common/diagnostics.js';
import { createHandleSummary }           from '../common/summary.js';

export const handleSummary = createHandleSummary('launchCustomerSales');

import { default as customerTest,   setup as setupCustomer,   teardown as teardownCustomer   } from './crud/customer.js';
import { default as billtoTest,     setup as setupBillto,     teardown as teardownBillto     } from './crud/billto.js';
import { default as shiptoTest,     setup as setupShipto,     teardown as teardownShipto     } from './crud/shipto.js';
import { default as salesrepTest,   setup as setupSalesrep,   teardown as teardownSalesrep   } from './crud/salesrep.js';
import { default as orderTest,      setup as setupOrder,      teardown as teardownOrder      } from './crud/order.js';
import { default as orderlineTest,  setup as setupOrderline,  teardown as teardownOrderline  } from './crud/orderline.js';
import { default as invoiceTest,    setup as setupInvoice,    teardown as teardownInvoice    } from './crud/invoice.js';
import { default as feedbackTest,   setup as setupFeedback,   teardown as teardownFeedback   } from './crud/feedback.js';
import { default as refcallTest,    setup as setupRefcall,    teardown as teardownRefcall    } from './crud/refcall.js';

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
  tags: { launcher: 'launchCustomerSales', ...(_cfg.options.tags || {}) },
  scenarios: {
    Customer:   { ...scenario, exec: 'Customer'  },
    Billto:     { ...scenario, exec: 'Billto'    },
    Shipto:     { ...scenario, exec: 'Shipto'    },
    Salesrep:   { ...scenario, exec: 'Salesrep'  },
    Order:      { ...scenario, exec: 'Order'     },
    Orderline:  { ...scenario, exec: 'Orderline' },
    Invoice:    { ...scenario, exec: 'Invoice'   },
    Feedback:   { ...scenario, exec: 'Feedback'  },
    Refcall:    { ...scenario, exec: 'Refcall'   },
  },
  thresholds: {
    http_req_failed: ['rate<0.05'],
    checks:          ['rate>=0.95'],
  },
};
logResolvedConfig(_cfg, options);

/**
 * Returns namespaced data so each scenario receives only its own slice.
 * @returns {object} Namespaced setup data keyed by test name.
 */
export function setup() {
  const dependencyRegistry = {};
  const setupContext = { dependencyRegistry };

  const salesrep  = setupSalesrep(setupContext);
  dependencyRegistry.salesrep = salesrep;

  const customer  = setupCustomer(setupContext);
  dependencyRegistry.customer = customer;

  const invoice   = setupInvoice(setupContext);
  const feedback  = setupFeedback(setupContext);
  const billto    = setupBillto(setupContext);
  const shipto    = setupShipto(setupContext);
  const refcall   = setupRefcall(setupContext);
  const order     = setupOrder(setupContext);
  dependencyRegistry.order = order;

  const orderline = setupOrderline(setupContext);
  dependencyRegistry.orderline = orderline;

  return { customer, billto, shipto, salesrep, order, orderline, invoice, feedback, refcall };
}

// Wrapper scenario functions - each receives the full combined data object
// and passes only its own namespace slice to the underlying test default.
export function Customer(data)  { customerTest(data.customer);   }
export function Billto(data)    { billtoTest(data.billto);       }
export function Shipto(data)    { shiptoTest(data.shipto);       }
export function Salesrep(data)  { salesrepTest(data.salesrep);   }
export function Order(data)     { orderTest(data.order);         }
export function Orderline(data) { orderlineTest(data.orderline); }
export function Invoice(data)   { invoiceTest(data.invoice);     }
export function Feedback(data)  { feedbackTest(data.feedback);   }
export function Refcall(data)   { refcallTest(data.refcall);     }

/**
 * Combined teardown - removes seeded data in reverse FK order.
 * orderline deleted before order; billto/shipto/refcall/order before customer.
 * @param {object} data Combined setup data.
 */
export function teardown(data) {
  teardownOrderline(data.orderline);
  teardownBillto(data.billto);
  teardownShipto(data.shipto);
  teardownRefcall(data.refcall);
  teardownOrder(data.order);
  teardownInvoice(data.invoice);
  teardownFeedback(data.feedback);
  teardownCustomer(data.customer);
  teardownSalesrep(data.salesrep);
}