/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 *
 * k6 scenario launcher for all Procedures service tests.
 *
 * Usage:
 *   k6 run --env CONFIG_FILE=configs/smoke-local.json    launchProcedures.js
 *   k6 run --env CONFIG_FILE=configs/load-baseline.json  launchProcedures.js
 *   k6 run                                               launchProcedures.js  (smoke defaults)
 */

import { buildLauncherScenarioFromProfile, buildTopLevelProfileOptions } from './common/scenarios.js';
import { loadConfig, logResolvedConfig } from './common/configLoader.js';
import { setProfile, applyEnvConfig }    from './common/config.js';
import { applyAuthConfig }               from './common/auth.js';
import { applyDiagnosticsConfig }        from './common/diagnostics.js';
import { createHandleSummary }           from './common/summary.js';

export const handleSummary = createHandleSummary('launchProcedures');

import { default as testFloatAddition }          from './scripts/procedures/floataddition.js';
import { default as testFloatDivision }          from './scripts/procedures/floatdivision.js';
import { default as testFloatMultiplication }    from './scripts/procedures/floatmultiplication.js';
import { default as testFloatSubtraction }       from './scripts/procedures/floatsubtraction.js';
import { default as testIntegerAddition }        from './scripts/procedures/integeraddition.js';
import { default as testIntegerDivision }        from './scripts/procedures/integerdivision.js';
import { default as testIntegerMultiplication }  from './scripts/procedures/integermultiplication.js';
import { default as testIntegerSubtraction }     from './scripts/procedures/integersubtraction.js';
import { default as testLongAddition }           from './scripts/procedures/longaddition.js';
import { default as testLongDivision }           from './scripts/procedures/longdivision.js';
import { default as testLongMultiplication }     from './scripts/procedures/longmultiplication.js';
import { default as testLongSubtraction }        from './scripts/procedures/longsubtraction.js';
import { default as testStringLongWhatLetter }   from './scripts/procedures/stringlongwhatletter.js';
import { default as testStringLongWhatWord }     from './scripts/procedures/stringlongwhatword.js';
import { default as testStringShortFindIn }      from './scripts/procedures/stringshortfindin.js';
import { default as testStringShortHelloJoin }   from './scripts/procedures/stringshorthellojoin.js';
import { default as testStringShortWhatLetter }  from './scripts/procedures/stringshortwhatletter.js';
import { default as testStringShortWhatWord }    from './scripts/procedures/stringshortwhatword.js';
import { default as testTemptableCreateDynamic } from './scripts/procedures/temptablecreatedynamic.js';
import { default as testTemptableCreateStatic }  from './scripts/procedures/temptablecreatestatic.js';
// NOTE: ProceduresTemptableAddRecords and ProceduresTemptableDeleteTable are excluded
// from this launcher because of the stateless-session handle bug (ABL error 3135).
// They remain available as standalone test files for when the server issue is resolved.

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
  tags: { launcher: 'launchProcedures', ...(_cfg.options.tags || {}) },
  scenarios: {
    FloatAddition:         { ...scenario, exec: 'testFloatAddition'         },
    FloatDivision:         { ...scenario, exec: 'testFloatDivision'         },
    FloatMultiplication:   { ...scenario, exec: 'testFloatMultiplication'   },
    FloatSubtraction:      { ...scenario, exec: 'testFloatSubtraction'      },
    IntegerAddition:       { ...scenario, exec: 'testIntegerAddition'       },
    IntegerDivision:       { ...scenario, exec: 'testIntegerDivision'       },
    IntegerMultiplication: { ...scenario, exec: 'testIntegerMultiplication' },
    IntegerSubtraction:    { ...scenario, exec: 'testIntegerSubtraction'    },
    LongAddition:          { ...scenario, exec: 'testLongAddition'          },
    LongDivision:          { ...scenario, exec: 'testLongDivision'          },
    LongMultiplication:    { ...scenario, exec: 'testLongMultiplication'    },
    LongSubtraction:       { ...scenario, exec: 'testLongSubtraction'       },
    StringLongWhatLetter:  { ...scenario, exec: 'testStringLongWhatLetter'  },
    StringLongWhatWord:    { ...scenario, exec: 'testStringLongWhatWord'    },
    StringShortFindIn:     { ...scenario, exec: 'testStringShortFindIn'     },
    StringShortHelloJoin:  { ...scenario, exec: 'testStringShortHelloJoin'  },
    StringShortWhatLetter: { ...scenario, exec: 'testStringShortWhatLetter' },
    StringShortWhatWord:   { ...scenario, exec: 'testStringShortWhatWord'   },
    TemptableCreateDynamic:{ ...scenario, exec: 'testTemptableCreateDynamic'},
    TemptableCreateStatic: { ...scenario, exec: 'testTemptableCreateStatic' },
    // TemptableAddRecords and TemptableDeleteTable excluded - server-side ABL error 3135.
  },
  thresholds: {
    http_req_failed: ['rate==0'],
    checks:          ['rate==1'],
    ...(_cfg.options.thresholds || {}),
  },
};
logResolvedConfig(_cfg, options);

// Re-export imported defaults so k6 can resolve the exec names above.
export {
  testFloatAddition,
  testFloatDivision,
  testFloatMultiplication,
  testFloatSubtraction,
  testIntegerAddition,
  testIntegerDivision,
  testIntegerMultiplication,
  testIntegerSubtraction,
  testLongAddition,
  testLongDivision,
  testLongMultiplication,
  testLongSubtraction,
  testStringLongWhatLetter,
  testStringLongWhatWord,
  testStringShortFindIn,
  testStringShortHelloJoin,
  testStringShortWhatLetter,
  testStringShortWhatWord,
  testTemptableCreateDynamic,
  testTemptableCreateStatic,
};