/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 *
 * k6 true-chaos scenario launcher for all currently working test groups.
 *
 * Includes:
 * - CRUD groups: Employee & HR, Customer & Sales, Inventory & Supply Chain, System & Configuration
 * - Objects service tests
 *
 * Excludes:
 * - Procedures service tests (currently server-blocked: HTTP 500 / ABL error 5425)
 * - TemptableAddRecords / TemptableDeleteTable (server-side ABL error 3135)
 *
 * Usage:
 *   k6 run --env CONFIG_FILE=configs/chaos-60m.json launchMultiScenario.js
 *   k6 run                                          launchMultiScenario.js   (smoke defaults)
 */

import { loadConfig, logResolvedConfig }        from './common/configLoader.js';
import { setProfile, applyEnvConfig }           from './common/config.js';
import { applyAuthConfig }                      from './common/auth.js';
import { applyDiagnosticsConfig }               from './common/diagnostics.js';
import { generateRandomStages, makeChaosScenario, buildTopLevelProfileOptions } from './common/scenarios.js';
import { createHandleSummary }                  from './common/summary.js';

export const handleSummary = createHandleSummary('launchMultiScenario');

// Prepare tests similar to launchEmployeeHR
import { default as departmentTest, setup as setupDepartment, teardown as teardownDept      } from './scripts/crud/department.js';
import { default as employeeTest,   setup as setupEmployee,   teardown as teardownEmp       } from './scripts/crud/employee.js';
import { default as benefitsTest,   setup as setupBenefits,   teardown as teardownBenefits  } from './scripts/crud/benefits.js';
import { default as familyTest,     setup as setupFamily,     teardown as teardownFamily    } from './scripts/crud/family.js';
import { default as timesheetTest,  setup as setupTimesheet,  teardown as teardownTimesheet } from './scripts/crud/timesheet.js';
import { default as vacationTest,   setup as setupVacation,   teardown as teardownVacation  } from './scripts/crud/vacation.js';

// Prepare tests similar to launchCustomerSales
import { default as customerTest,   setup as setupCustomer,   teardown as teardownCustomer  } from './scripts/crud/customer.js';
import { default as billtoTest,     setup as setupBillto,     teardown as teardownBillto    } from './scripts/crud/billto.js';
import { default as shiptoTest,     setup as setupShipto,     teardown as teardownShipto    } from './scripts/crud/shipto.js';
import { default as salesrepTest,   setup as setupSalesrep,   teardown as teardownSalesrep  } from './scripts/crud/salesrep.js';
import { default as orderTest,      setup as setupOrder,      teardown as teardownOrder     } from './scripts/crud/order.js';
import { default as orderlineTest,  setup as setupOrderline,  teardown as teardownOrderline } from './scripts/crud/orderline.js';
import { default as invoiceTest,    setup as setupInvoice,    teardown as teardownInvoice   } from './scripts/crud/invoice.js';
import { default as feedbackTest,   setup as setupFeedback,   teardown as teardownFeedback  } from './scripts/crud/feedback.js';
import { default as refcallTest,    setup as setupRefcall,    teardown as teardownRefcall   } from './scripts/crud/refcall.js';

// Prepare tests similar to launchInventorySupplyChain
import { default as itemTest,             setup as setupItem,             teardown as teardownItem             } from './scripts/crud/item.js';
import { default as binTest,              setup as setupBin,              teardown as teardownBin              } from './scripts/crud/bin.js';
import { default as warehouseTest,        setup as setupWarehouse,        teardown as teardownWarehouse        } from './scripts/crud/warehouse.js';
import { default as inventorytransTest,   setup as setupInventorytrans,   teardown as teardownInventorytrans   } from './scripts/crud/inventorytrans.js';
import { default as supplierTest,         setup as setupSupplier,         teardown as teardownSupplier         } from './scripts/crud/supplier.js';
import { default as supplieritemxrefTest, setup as setupSupplieritemxref, teardown as teardownSupplieritemxref } from './scripts/crud/supplieritemxref.js';
import { default as purchaseorderTest,    setup as setupPurchaseorder,    teardown as teardownPurchaseorder    } from './scripts/crud/purchaseorder.js';
import { default as polineTest,           setup as setupPoline,           teardown as teardownPoline           } from './scripts/crud/poline.js';

// Prepare tests similar to launchSystemConfig
import { default as stateTest,        setup as setupState,        teardown as teardownState        } from './scripts/crud/state.js';
import { default as localdefaultTest, setup as setupLocaldefault, teardown as teardownLocaldefault } from './scripts/crud/localdefault.js';

// Prepare tests similar to launchObjects
import { default as objFloatAddition }          from './scripts/objects/floataddition.js';
import { default as objFloatDivision }          from './scripts/objects/floatdivision.js';
import { default as objFloatMultiplication }    from './scripts/objects/floatmultiplication.js';
import { default as objFloatSubtraction }       from './scripts/objects/floatsubtraction.js';
import { default as objIntegerAddition }        from './scripts/objects/integeraddition.js';
import { default as objIntegerDivision }        from './scripts/objects/integerdivision.js';
import { default as objIntegerMultiplication }  from './scripts/objects/integermultiplication.js';
import { default as objIntegerSubtraction }     from './scripts/objects/integersubtraction.js';
import { default as objLongAddition }           from './scripts/objects/longaddition.js';
import { default as objLongDivision }           from './scripts/objects/longdivision.js';
import { default as objLongMultiplication }     from './scripts/objects/longmultiplication.js';
import { default as objLongSubtraction }        from './scripts/objects/longsubtraction.js';
import { default as objStringLongWhatLetter }   from './scripts/objects/stringlongwhatletter.js';
import { default as objStringLongWhatWord }     from './scripts/objects/stringlongwhatword.js';
import { default as objStringShortFindIn }      from './scripts/objects/stringshortfindin.js';
import { default as objStringShortHelloJoin }   from './scripts/objects/stringshorthellojoin.js';
import { default as objStringShortWhatLetter }  from './scripts/objects/stringshortwhatletter.js';
import { default as objStringShortWhatWord }    from './scripts/objects/stringshortwhatword.js';
import { default as objTemptableCreateDynamic } from './scripts/objects/temptablecreatedynamic.js';
import { default as objTemptableCreateStatic }  from './scripts/objects/temptablecreatestatic.js';

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

const topLevelOptions = buildTopLevelProfileOptions();
export const options = {
  ...topLevelOptions,
  tags: { ...(_cfg.options.tags || {}), launcher: 'launchMultiScenario' },
  scenarios: {
    Department: makeChaosScenario('Department'),
    Employee: makeChaosScenario('Employee'),
    Benefits: makeChaosScenario('Benefits'),
    Family: makeChaosScenario('Family'),
    Timesheet: makeChaosScenario('Timesheet'),
    Vacation: makeChaosScenario('Vacation'),

    Customer: makeChaosScenario('Customer'),
    Billto: makeChaosScenario('Billto'),
    Shipto: makeChaosScenario('Shipto'),
    Salesrep: makeChaosScenario('Salesrep'),
    Order: makeChaosScenario('Order'),
    Orderline: makeChaosScenario('Orderline'),
    Invoice: makeChaosScenario('Invoice'),
    Feedback: makeChaosScenario('Feedback'),
    Refcall: makeChaosScenario('Refcall'),

    Item: makeChaosScenario('Item'),
    Bin: makeChaosScenario('Bin'),
    Warehouse: makeChaosScenario('Warehouse'),
    Inventorytrans: makeChaosScenario('Inventorytrans'),
    Supplier: makeChaosScenario('Supplier'),
    Supplieritemxref: makeChaosScenario('Supplieritemxref'),
    Purchaseorder: makeChaosScenario('Purchaseorder'),
    Poline: makeChaosScenario('Poline'),

    State: makeChaosScenario('State'),
    Localdefault: makeChaosScenario('Localdefault'),

    FloatAddition: makeChaosScenario('testFloatAddition'),
    FloatDivision: makeChaosScenario('testFloatDivision'),
    FloatMultiplication: makeChaosScenario('testFloatMultiplication'),
    FloatSubtraction: makeChaosScenario('testFloatSubtraction'),
    IntegerAddition: makeChaosScenario('testIntegerAddition'),
    IntegerDivision: makeChaosScenario('testIntegerDivision'),
    IntegerMultiplication: makeChaosScenario('testIntegerMultiplication'),
    IntegerSubtraction: makeChaosScenario('testIntegerSubtraction'),
    LongAddition: makeChaosScenario('testLongAddition'),
    LongDivision: makeChaosScenario('testLongDivision'),
    LongMultiplication: makeChaosScenario('testLongMultiplication'),
    LongSubtraction: makeChaosScenario('testLongSubtraction'),
    StringLongWhatLetter: makeChaosScenario('testStringLongWhatLetter'),
    StringLongWhatWord: makeChaosScenario('testStringLongWhatWord'),
    StringShortFindIn: makeChaosScenario('testStringShortFindIn'),
    StringShortHelloJoin: makeChaosScenario('testStringShortHelloJoin'),
    StringShortWhatLetter: makeChaosScenario('testStringShortWhatLetter'),
    StringShortWhatWord: makeChaosScenario('testStringShortWhatWord'),
    TemptableCreateDynamic: makeChaosScenario('testTemptableCreateDynamic'),
    TemptableCreateStatic: makeChaosScenario('testTemptableCreateStatic'),
  },
  setupTimeout:    _cfg.options.setupTimeout    || '20m',
  teardownTimeout: _cfg.options.teardownTimeout || '20m',
  thresholds: {
    'checks{profile:chaos}':          ['rate>=0.95'],
    'http_req_failed{profile:chaos}': ['rate<0.05'],
    ...(_cfg.options.thresholds || {}),
  },
  tags: {
    ...(_cfg.options.tags || {}),
    launcher: 'launchMultiScenario',
  }
};
logResolvedConfig(_cfg, options);

export function setup() {
  const dependencyRegistry = {};
  const setupContext = { dependencyRegistry };

  const department = setupDepartment(setupContext);
  dependencyRegistry.department = department;
  const employee = setupEmployee(setupContext);
  dependencyRegistry.employee = employee;

  const salesrep = setupSalesrep(setupContext);
  dependencyRegistry.salesrep = salesrep;
  const customer = setupCustomer(setupContext);
  dependencyRegistry.customer = customer;
  const order = setupOrder(setupContext);
  dependencyRegistry.order = order;

  const item = setupItem(setupContext);
  dependencyRegistry.item = item;
  const warehouse = setupWarehouse(setupContext);
  dependencyRegistry.warehouse = warehouse;
  const supplier = setupSupplier(setupContext);
  dependencyRegistry.supplier = supplier;
  const purchaseorder = setupPurchaseorder(setupContext);
  dependencyRegistry.purchaseorder = purchaseorder;

  return {
    department,
    employee,
    benefits: setupBenefits(setupContext),
    family: setupFamily(setupContext),
    timesheet: setupTimesheet(setupContext),
    vacation: setupVacation(setupContext),

    salesrep,
    invoice: setupInvoice(setupContext),
    feedback: setupFeedback(setupContext),
    customer,
    billto: setupBillto(setupContext),
    shipto: setupShipto(setupContext),
    refcall: setupRefcall(setupContext),
    order,
    orderline: setupOrderline(setupContext),

    bin: setupBin(setupContext),
    warehouse,
    inventorytrans: setupInventorytrans(setupContext),
    item,
    supplier,
    purchaseorder,
    supplieritemxref: setupSupplieritemxref(setupContext),
    poline: setupPoline(setupContext),

    state: setupState(setupContext),
    localdefault: setupLocaldefault(setupContext),
  };
}

export function Department(data) { departmentTest(data.department); }
export function Employee(data) { employeeTest(data.employee); }
export function Benefits(data) { benefitsTest(data.benefits); }
export function Family(data) { familyTest(data.family); }
export function Timesheet(data) { timesheetTest(data.timesheet); }
export function Vacation(data) { vacationTest(data.vacation); }

export function Customer(data) { customerTest(data.customer); }
export function Billto(data) { billtoTest(data.billto); }
export function Shipto(data) { shiptoTest(data.shipto); }
export function Salesrep(data) { salesrepTest(data.salesrep); }
export function Order(data) { orderTest(data.order); }
export function Orderline(data) { orderlineTest(data.orderline); }
export function Invoice(data) { invoiceTest(data.invoice); }
export function Feedback(data) { feedbackTest(data.feedback); }
export function Refcall(data) { refcallTest(data.refcall); }

export function Item(data) { itemTest(data.item); }
export function Bin(data) { binTest(data.bin); }
export function Warehouse(data) { warehouseTest(data.warehouse); }
export function Inventorytrans(data) { inventorytransTest(data.inventorytrans); }
export function Supplier(data) { supplierTest(data.supplier); }
export function Supplieritemxref(data) { supplieritemxrefTest(data.supplieritemxref); }
export function Purchaseorder(data) { purchaseorderTest(data.purchaseorder); }
export function Poline(data) { polineTest(data.poline); }

export function State(data) { stateTest(data.state); }
export function Localdefault(data) { localdefaultTest(data.localdefault); }

export function testFloatAddition() { objFloatAddition(); }
export function testFloatDivision() { objFloatDivision(); }
export function testFloatMultiplication() { objFloatMultiplication(); }
export function testFloatSubtraction() { objFloatSubtraction(); }
export function testIntegerAddition() { objIntegerAddition(); }
export function testIntegerDivision() { objIntegerDivision(); }
export function testIntegerMultiplication() { objIntegerMultiplication(); }
export function testIntegerSubtraction() { objIntegerSubtraction(); }
export function testLongAddition() { objLongAddition(); }
export function testLongDivision() { objLongDivision(); }
export function testLongMultiplication() { objLongMultiplication(); }
export function testLongSubtraction() { objLongSubtraction(); }
export function testStringLongWhatLetter() { objStringLongWhatLetter(); }
export function testStringLongWhatWord() { objStringLongWhatWord(); }
export function testStringShortFindIn() { objStringShortFindIn(); }
export function testStringShortHelloJoin() { objStringShortHelloJoin(); }
export function testStringShortWhatLetter() { objStringShortWhatLetter(); }
export function testStringShortWhatWord() { objStringShortWhatWord(); }
export function testTemptableCreateDynamic() { objTemptableCreateDynamic(); }
export function testTemptableCreateStatic() { objTemptableCreateStatic(); }

export function teardown(data) {
  teardownBenefits(data.benefits);
  teardownFamily(data.family);
  teardownTimesheet(data.timesheet);
  teardownVacation(data.vacation);
  teardownEmp(data.employee);
  teardownDept(data.department);

  teardownOrderline(data.orderline);
  teardownBillto(data.billto);
  teardownShipto(data.shipto);
  teardownRefcall(data.refcall);
  teardownOrder(data.order);
  teardownInvoice(data.invoice);
  teardownFeedback(data.feedback);
  teardownCustomer(data.customer);
  teardownSalesrep(data.salesrep);

  teardownSupplieritemxref(data.supplieritemxref);
  teardownPoline(data.poline);
  teardownItem(data.item);
  teardownSupplier(data.supplier);
  teardownPurchaseorder(data.purchaseorder);
  teardownBin(data.bin);
  teardownWarehouse(data.warehouse);
  teardownInventorytrans(data.inventorytrans);

  teardownState(data.state);
  teardownLocaldefault(data.localdefault);
}
