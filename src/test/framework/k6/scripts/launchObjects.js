/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 *
 * k6 scenario launcher for all Objects service tests.
 *
 * Usage:
 *   k6 run --env CONFIG_FILE=configs/smoke-local.json    launchObjects.js
 *   k6 run --env CONFIG_FILE=configs/load-baseline.json  launchObjects.js
 *   k6 run                                               launchObjects.js  (smoke defaults)
 */

import { buildLauncherScenarioFromProfile } from '../common/scenarios.js';
import { loadConfig, logResolvedConfig } from '../common/configLoader.js';
import { setProfile, applyEnvConfig }    from '../common/config.js';
import { applyAuthConfig, AUTH_STICKY_SESSIONS } from '../common/auth.js';
import { applyDiagnosticsConfig }        from '../common/diagnostics.js';
import { createHandleSummary }           from '../common/summary.js';

export const handleSummary = createHandleSummary('launchObjects');

import { default as testFloatAddition }           from './objects/floataddition.js';
import { default as testFloatDivision }           from './objects/floatdivision.js';
import { default as testFloatMultiplication }     from './objects/floatmultiplication.js';
import { default as testFloatSubtraction }        from './objects/floatsubtraction.js';
import { default as testIntegerAddition }         from './objects/integeraddition.js';
import { default as testIntegerDivision }         from './objects/integerdivision.js';
import { default as testIntegerMultiplication }   from './objects/integermultiplication.js';
import { default as testIntegerSubtraction }      from './objects/integersubtraction.js';
import { default as testLongAddition }            from './objects/longaddition.js';
import { default as testLongDivision }            from './objects/longdivision.js';
import { default as testLongMultiplication }      from './objects/longmultiplication.js';
import { default as testLongSubtraction }         from './objects/longsubtraction.js';
import { default as testStringLongWhatLetter }    from './objects/stringlongwhatletter.js';
import { default as testStringLongWhatWord }      from './objects/stringlongwhatword.js';
import { default as testStringShortFindIn }       from './objects/stringshortfindin.js';
import { default as testStringShortHelloJoin }    from './objects/stringshorthellojoin.js';
import { default as testStringShortWhatLetter }   from './objects/stringshortwhatletter.js';
import { default as testStringShortWhatWord }     from './objects/stringshortwhatword.js';
import { default as testTemptableCreateDynamic }  from './objects/temptablecreatedynamic.js';
import { default as testTemptableCreateStatic }   from './objects/temptablecreatestatic.js';
// NOTE: ObjectsTemptableAddRecords and ObjectsTemptableDeleteTable are excluded from this
// launcher because the server returns HTTP 500 (ABL error 3135 - stateless-session handle bug).
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

const { systemTags, ...scenario } = buildLauncherScenarioFromProfile();

export const options = {
  noCookiesReset: AUTH_STICKY_SESSIONS,
  setupTimeout:    _cfg.options.setupTimeout    || '5m',
  teardownTimeout: _cfg.options.teardownTimeout || '5m',
  tags: { launcher: 'launchObjects', ...(_cfg.options.tags || {}) },
  scenarios: {
    FloatAddition:         { ...scenario, exec: 'testFloatAddition' },
    FloatDivision:         { ...scenario, exec: 'testFloatDivision' },
    FloatMultiplication:   { ...scenario, exec: 'testFloatMultiplication' },
    FloatSubtraction:      { ...scenario, exec: 'testFloatSubtraction' },
    IntegerAddition:       { ...scenario, exec: 'testIntegerAddition' },
    IntegerDivision:       { ...scenario, exec: 'testIntegerDivision' },
    IntegerMultiplication: { ...scenario, exec: 'testIntegerMultiplication' },
    IntegerSubtraction:    { ...scenario, exec: 'testIntegerSubtraction' },
    LongAddition:          { ...scenario, exec: 'testLongAddition' },
    LongDivision:          { ...scenario, exec: 'testLongDivision' },
    LongMultiplication:    { ...scenario, exec: 'testLongMultiplication' },
    LongSubtraction:       { ...scenario, exec: 'testLongSubtraction' },
    StringLongWhatLetter:  { ...scenario, exec: 'testStringLongWhatLetter' },
    StringLongWhatWord:    { ...scenario, exec: 'testStringLongWhatWord' },
    StringShortFindIn:     { ...scenario, exec: 'testStringShortFindIn' },
    StringShortHelloJoin:  { ...scenario, exec: 'testStringShortHelloJoin' },
    StringShortWhatLetter: { ...scenario, exec: 'testStringShortWhatLetter' },
    StringShortWhatWord:   { ...scenario, exec: 'testStringShortWhatWord' },
    TemptableCreateDynamic:{ ...scenario, exec: 'testTemptableCreateDynamic' },
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