/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 */

/**
 * Virtual User Authentication Module for k6 Load Tests
 *
 * This module manages per-Virtual User (VU) authentication within k6's distributed execution model.
 * Understanding k6's execution contexts is essential to using this module correctly:
 *
 * ═══════════════════════════════════════════════════════════════════════════════════════════════
 * K6 EXECUTION MODEL - Three Distinct Phases and Contexts
 * ═══════════════════════════════════════════════════════════════════════════════════════════════
 *
 * 1. SETUP PHASE (global context)
 *    ────────────────────────────────
 *    • Runs: ONCE, before any VUs are spawned
 *    • Execution context: MAIN/GLOBAL (not a VU)
 *    • __VU value: undefined
 *    • Cookie jar: SHARED (main context's jar)
 *    • Purpose: Create test data, initialize databases, warm up endpoints
 *    • Authentication: Typically unauthenticated (system/anonymous context)
 *    • Example code in setup():
 *
 *      // This runs ONCE before VU spawning. No __VU available.
 *      // If you call http.post(), it uses the shared main cookie jar.
 *      export function setup() {
 *        return generateTestData(); // No VU isolation
 *      }
 *
 *
 * 2. DEFAULT PHASE (per-VU contexts, iterations)
 *    ──────────────────────────────────────────────
 *    • Runs: REPEATEDLY, one function per VU in parallel
 *    • Execution context: ISOLATED PER VU (each VU has its own context)
 *    • __VU value: defined (e.g., 1, 2, 3... for 3 VUs)
 *    • Cookie jar: ISOLATED PER VU (each VU maintains its own cookies)
 *    • Purpose: Simulate load - each VU acts as a separate user making repeated requests
 *    • Authentication: Per-VU authenticated (each VU logs in once, reuses session)
 *    • Iterations: Executor-dependent. For `shared-iterations`, all VUs pull
 *      work from one shared total iteration pool.
 *
 *    KEY CONCEPT - Shared Iterations and Session Persistence:
 *    ───────────────────────────────────────────────────────
 *    Consider 2 VUs, 6 total shared iterations:
 *
 *      VU 1's Timeline:              VU 2's Timeline:
 *      ┌─ Iteration A                ┌─ Iteration B
 *      │  - Login (new JSESSIONID)   │  - Login (new JSESSIONID)
 *      │  - Make API calls           │  - Make API calls
 *      │  - (Logout if configured)   │  - (Logout if configured)
 *      ├─ Iteration C (if scheduled) ├─ Iteration D (if scheduled)
 *      │  - Reuse JSESSIONID if held │  - Reuse JSESSIONID if held
 *      │  - Make API calls           │  - Make API calls
 *      │  - (Logout if configured)   │  - (Logout if configured)
 *      └─ ... until shared pool exhausted for the scenario ...
 *
 *    Each VU's JSESSIONID cookie stays in its isolated cookie jar across iterations,
 *    UNLESS explicitly logged out. This module tracks authentication state per-VU
 *    with the isVirtualUserAuthenticated flag (module-level variable).
 *
 *    IMPORTANT: The isVirtualUserAuthenticated flag is NOT an array or map.
 *    It's a single boolean. How does it work with multiple VUs?
 *    ANSWER: JavaScript module state is evaluated in the VU's context.
 *    Each VU gets a CLONE of the module with its own module-level state.
 *    So each VU has its own isVirtualUserAuthenticated boolean.
 *
 * 3. TEARDOWN PHASE (global context)
 *    ────────────────────────────────
 *    • Runs: ONCE, after all VUs have completed
 *    • Execution context: MAIN/GLOBAL (not a VU)
 *    • __VU value: undefined
 *    • Cookie jar: SHARED (main context's jar)
 *    • Purpose: Cleanup, generate reports, verify final state
 *    • Authentication: Typically unauthenticated (any cookies from setup still available, but VU cookies are gone)
 *    • Example code in teardown():
 *
 *      export function teardown(data) {
 *        // No VU exists here. VU sessions are finished.
 *        // Useful for deleting test data or resetting state.
 *      }
 *
 *
 * ═══════════════════════════════════════════════════════════════════════════════════════════════
 * HOW AUTHENTICATION FLOWS IN THIS MODULE
 * ═══════════════════════════════════════════════════════════════════════════════════════════════
 *
 * Typical load test execution:
 *
 *   setup()
 *   │
 *   ├─ Create test data (e.g., departments, employees) - unauthenticated, main jar
 *   └─ Return data to make available to default() phases
 *
 *   default() - VU 1, Iteration 1       default() - VU 2, Iteration 1
 *   │                                   │
 *   ├─ ensureAuthenticationIfRequired() ├─ ensureAuthenticationIfRequired()
 *   │  └─ Username: oels-vu-1           │  └─ Username: oels-vu-2
 *   │  └─ POSTs to /j_spring_security   │  └─ POSTs to /j_spring_security
 *   │  └─ Gets JSESSIONID (jar 1)       │  └─ Gets JSESSIONID (jar 2)
 *   │                                   │
 *   ├─ Make authenticated API calls     ├─ Make authenticated API calls
 *   │                                   │
 *   ├─ (Optional: logout)               ├─ (Optional: logout)
 *   │  [JSESSIONID cleared]             │  [JSESSIONID cleared]
 *   └─ default() - VU 1 iteration ends  └─ default() - VU 2 iteration ends
 *
 *   default() - VU 1, Iteration 2        default() - VU 2, Iteration 2
 *   │                                    │
 *   ├─ ensureAuthenticationIfRequired()  ├─ ensureAuthenticationIfRequired()
 *   │  ├─ Check: Are we already authed?  │  ├─ Check: Are we already authed?
 *   │  │  (Yes, if not logged out)       │  │  (Yes, if not logged out)
 *   │  ├─ Check: JSESSIONID still exist? │  ├─ Check: JSESSIONID still exist?
 *   │  │  (Yes in jar 1)                 │  │  (Yes in jar 2)
 *   │  └─ Skip login, reuse session      │  └─ Skip login, reuse session
 *   │                                    │
 *   ├─ Make authenticated API calls      ├─ Make authenticated API calls
 *   │  (using JSESSIONID from jar)       │  (using JSESSIONID from jar)
 *   │                                    │
 *   ├─ (Optional: logout)                ├─ (Optional: logout)
 *   │  [JSESSIONID cleared]              │  [JSESSIONID cleared]
 *   └─ default() - VU 1 iteration ends   └─ default() - VU 2 iteration ends
 *
 *   ... (iterations 3 and beyond follow same pattern) ...
 *
 *   teardown()
 *   │
 *   └─ VU sessions are gone; only main context jar remains
 *      Use for cleanup if needed
 *
 * ═══════════════════════════════════════════════════════════════════════════════════════════════
 * LOGOUT TIMING AND AUTH_LOGOUT_EACH_ITERATION
 * ═══════════════════════════════════════════════════════════════════════════════════════════════
 *
 * The AUTH_LOGOUT_EACH_ITERATION environment variable controls when session ends:
 *
 *   AUTH_LOGOUT_EACH_ITERATION=false (DEFAULT)
 *   ──────────────────────────────────────────
 *   • Logout is NOT called automatically
 *   • JSESSIONID persists across iterations within the same VU
 *   • Same user (same username) stays authenticated for all its iterations
 *   • Mimics real user behavior: log in once, make multiple requests, session expires naturally
 *   • Use case: Most load tests (want to minimize auth overhead)
 *
 *   AUTH_LOGOUT_EACH_ITERATION=true
 *   ───────────────────────────────
 *   • runWithVirtualUserAuthentication() calls logout at END of each iteration
 *   • JSESSIONID is cleared after each iteration
 *   • Next iteration forces fresh login (same VU, same username)
 *   • Use case: Stress-test the authentication system itself
 *   • Note: This is a DIFFERENT pattern than normal load testing
 *
 * Where does logout happen in the iteration flow?
 *
 *   Iteration N (with AUTH_LOGOUT_EACH_ITERATION=true):
 *   │
 *   ├─ ensureAuthenticationIfRequired()
 *   │  └─ Login if not authed, reuse session if possible
 *   │
 *   ├─ Make API calls, run test logic
 *   │
 *   ├─ runWithVirtualUserAuthentication() finally block:
 *   │  └─ Call logoutVirtualUserSession() IF AUTH_LOGOUT_EACH_ITERATION
 *   │     └─ POST to /j_spring_security_logout
 *   │     └─ Clear isVirtualUserAuthenticated flag
 *   │     └─ JSESSIONID removed from cookie jar
 *   │
 *   └─ (Iteration N ends)
 *
 *   Iteration N+1:
 *   │
 *   └─ Fresh login cycle begins (no session from previous iteration)
 *
 * Default behavior (AUTH_LOGOUT_EACH_ITERATION=false):
 *   No logout is called automatically. Session persists.
 *   If you want to explicitly logout, import and call logoutVirtualUserSession() yourself.
 *
 * ═══════════════════════════════════════════════════════════════════════════════════════════════
 * MODULE-LEVEL STATE AND VU ISOLATION
 * ═══════════════════════════════════════════════════════════════════════════════════════════════
 *
 * This module uses two module-level variables for authentication tracking:
 *   • isVirtualUserAuthenticated (boolean)
 *   • currentVirtualUserUsername (string)
 *
 * These look like "global" state, but they're NOT shared across VUs:
 *
 *   When k6 spawns VU 1, VU 2, VU 3:
 *   ────────────────────────────────
 *   • k6 initializes the module (imports auth.js) ONCE per VU
 *   • Each VU gets its OWN copy of the module with its OWN isVirtualUserAuthenticated
 *   • VU 1's isVirtualUserAuthenticated is independent from VU 2's
 *   • When VU 1 logs in, only VU 1's copy is set to true
 *   • VU 2's copy is still false (until VU 2 logs in)
 *   • This is k6's module isolation behavior - each VU context is sandboxed
 *
 * ═══════════════════════════════════════════════════════════════════════════════════════════════
 */

import http from 'k6/http';
import execution from 'k6/execution';
import { check, fail } from 'k6';
import { BASE_URL } from './config.js';
import { captureFailureContext } from './diagnostics.js';
import { labelCheckName } from './utils.js';

let AUTH_REQUIRED = String(__ENV.AUTH_REQUIRED || 'true').toLowerCase() !== 'false';
let AUTH_CONTEXT_PATH = __ENV.AUTH_CONTEXT_PATH || '/devsuite/static/auth';
let AUTH_LOGIN_ENDPOINT = __ENV.AUTH_LOGIN_ENDPOINT || `${AUTH_CONTEXT_PATH}/j_spring_security_check`;
let AUTH_LOGOUT_ENDPOINT = __ENV.AUTH_LOGOUT_ENDPOINT || `${AUTH_CONTEXT_PATH}/j_spring_security_logout`;
const AUTH_SESSION_COOKIE_NAME = 'JSESSIONID';
const AUTH_COOKIE_SCOPE_PATH = '/devsuite';
const AUTH_API_SCOPE_PATH = '/devsuite/web/api';
let AUTH_CONTEXT_API_PATH = __ENV.AUTH_CONTEXT_API_PATH || '/devsuite/web/api/context';
let AUTH_USERNAME_PREFIX = __ENV.AUTH_USERNAME_PREFIX || 'oels-vu';
let AUTH_PASSWORD = __ENV.AUTH_PASSWORD || 'password';
let AUTH_LOGOUT_EACH_ITERATION = String(__ENV.AUTH_LOGOUT_EACH_ITERATION || 'false').toLowerCase() === 'true';
let AUTH_SESSION_DURATION_SECONDS = parseInt(__ENV.AUTH_SESSION_DURATION_SECONDS || '0', 10);
let AUTH_DEBUG = String(__ENV.AUTH_DEBUG || 'false').toLowerCase() === 'true';
export let AUTH_STICKY_SESSIONS = String(__ENV.AUTH_STICKY_SESSIONS || 'true').toLowerCase() === 'true';

/**
 * Applies all auth-related values from a resolved config env section.
 * Handles AUTH_LOGIN_ENDPOINT / AUTH_LOGOUT_ENDPOINT derivation from AUTH_CONTEXT_PATH atomically.
 * Call this in launcher init context before export const options.
 * @param {object} env - The resolved config.env object from configLoader.loadConfig().
 */
export function applyAuthConfig(env) {
  if (!env) return;
  if (env.AUTH_REQUIRED              !== undefined) AUTH_REQUIRED              = Boolean(env.AUTH_REQUIRED);
  if (env.AUTH_USERNAME_PREFIX       !== undefined) AUTH_USERNAME_PREFIX       = String(env.AUTH_USERNAME_PREFIX);
  if (env.AUTH_PASSWORD              !== undefined) AUTH_PASSWORD              = String(env.AUTH_PASSWORD);
  if (env.AUTH_LOGOUT_EACH_ITERATION !== undefined) AUTH_LOGOUT_EACH_ITERATION = Boolean(env.AUTH_LOGOUT_EACH_ITERATION);
  if (env.AUTH_STICKY_SESSIONS       !== undefined) AUTH_STICKY_SESSIONS       = Boolean(env.AUTH_STICKY_SESSIONS);
  if (env.AUTH_DEBUG                 !== undefined) AUTH_DEBUG                 = Boolean(env.AUTH_DEBUG);
  if (env.AUTH_CONTEXT_API_PATH          !== undefined) AUTH_CONTEXT_API_PATH          = String(env.AUTH_CONTEXT_API_PATH);
  if (env.AUTH_SESSION_DURATION_SECONDS  !== undefined) AUTH_SESSION_DURATION_SECONDS  = parseInt(env.AUTH_SESSION_DURATION_SECONDS, 10);

  // Handle context path + derived endpoints atomically so they remain consistent.
  const contextPath = env.AUTH_CONTEXT_PATH !== undefined
                    ? String(env.AUTH_CONTEXT_PATH)
                    : AUTH_CONTEXT_PATH;
  AUTH_CONTEXT_PATH   = contextPath;
  AUTH_LOGIN_ENDPOINT = env.AUTH_LOGIN_ENDPOINT  !== undefined
                      ? String(env.AUTH_LOGIN_ENDPOINT)
                      : `${contextPath}/j_spring_security_check`;
  AUTH_LOGOUT_ENDPOINT = env.AUTH_LOGOUT_ENDPOINT !== undefined
                       ? String(env.AUTH_LOGOUT_ENDPOINT)
                       : `${contextPath}/j_spring_security_logout`;
}

const FORM_URLENCODED_HEADERS = Object.freeze({
  'Content-Type': 'application/x-www-form-urlencoded',
  'Accept': 'text/html,application/json,*/*',
});

/**
 * Per-process salt for Virtual User username generation.
 * Prevents username collisions when multiple k6 instances run concurrently
 * (e.g. distributed cloud or multi-node test clusters). Generated once at
 * init context using XOR of timestamp milliseconds and a random value to
 * eliminate NTP clock-sync collision risk.
 */
const _VU_INSTANCE_SALT = String((Date.now() % 1000 ^ Math.floor(Math.random() * 1000)) % 1000).padStart(3, '0');

let isVirtualUserAuthenticated = false;
let currentVirtualUserUsername = null;
let vuLastLoginTime = 0;
let configLogged = false;

/** ***** Begin Private Helper Functions ***** */

/**
 * Extracts cookie values for a specific URL from the current Virtual User cookie jar.
 * @param {string} url - Absolute URL used as cookie-jar lookup scope.
 * @returns {Record<string, string[]>} Cookie names and values.
 */
function cookieJarForUrl(url) {
  const jar = http.cookieJar();
  return jar.cookiesForURL(url) || {};
}

/**
 * Checks whether a JSESSIONID cookie is currently available in the VU cookie jar.
 *
 * This probes multiple paths because Tomcat cookie path scope can vary by deployment
 * (api path, app root, auth context, or site root).
 *
 * @returns {boolean} True when a session cookie is found in any expected scope.
 */
function hasApiScopeSessionCookie() {
  const probePaths = [AUTH_API_SCOPE_PATH, AUTH_COOKIE_SCOPE_PATH, AUTH_CONTEXT_PATH, '/'];

  for (const probePath of probePaths) {
    const scopedCookies = cookieJarForUrl(`${BASE_URL}${probePath}`);
    const jsessionValues = scopedCookies[AUTH_SESSION_COOKIE_NAME] || [];

    if (jsessionValues.length > 0) {
      return true;
    }
  }

  return false;
}

/**
 * Validates that JSESSIONID is available for the API request scope URL.
 * @param {string} username - Authenticated username.
 */
function assertApiScopeSessionCookie(username) {
  const cookieScopeUrl = `${BASE_URL}${AUTH_API_SCOPE_PATH}`;
  const scopedCookies = cookieJarForUrl(cookieScopeUrl);
  const jsessionValues = scopedCookies[AUTH_SESSION_COOKIE_NAME] || [];
  const cookieNames = Object.keys(scopedCookies);

  logAuthDebug(`cookie-scope username=${username} scope=${AUTH_API_SCOPE_PATH} cookies=${cookieNames.join(',') || '(none)'}`);

  if (jsessionValues.length > 0) {
    logAuthDebug(`JSESSIONID available: ${jsessionValues[0].substring(0, 20)}...`);
  } else {
    logAuthDebug(`WARNING: No JSESSIONID found for scope ${cookieScopeUrl}`);
  }

  if (jsessionValues.length === 0) {
    fail(
      `Authentication cookie scope failed for username=${username}. ` +
      `No JSESSIONID cookie available for ${cookieScopeUrl}. ` +
      `This usually means Tomcat set a narrower cookie path than API requests use.`
    );
  }
}

/**
 * Writes auth diagnostic output when debug is enabled.
 * @param {string} message - Diagnostic message.
 */
function logAuthDebug(message) {
  if (AUTH_DEBUG) {
    const vuId = execution.vu?.idInTest ?? __VU ?? 0;
    const iteration = execution.vu?.iterationInScenario ?? __ITER ?? 0;
    const scenarioName = execution.scenario?.name || 'default';
    console.log(`[auth] vu=${vuId} iter=${iteration} scenario=${scenarioName} | ${message}`);
  }
}

/**
 * Logs auth configuration on first VU initialization.
 */
function logAuthConfig() {
  if (configLogged) {
    return;
  }
  configLogged = true;

  logAuthDebug(`config: AUTH_REQUIRED=${AUTH_REQUIRED}`);
  logAuthDebug(`config: LOGIN_ENDPOINT=${AUTH_LOGIN_ENDPOINT}`);
  logAuthDebug(`config: LOGOUT_ENDPOINT=${AUTH_LOGOUT_ENDPOINT}`);
  logAuthDebug(`config: COOKIE_PROBE_ROOT=${AUTH_COOKIE_SCOPE_PATH}`);
  logAuthDebug(`config: API_SCOPE_PATH=${AUTH_API_SCOPE_PATH}`);
  logAuthDebug(`config: USERNAME_PREFIX=${AUTH_USERNAME_PREFIX}`);
  logAuthDebug(`config: LOGOUT_EACH_ITERATION=${AUTH_LOGOUT_EACH_ITERATION}`);
  logAuthDebug(`config: AUTH_STICKY_SESSIONS=${AUTH_STICKY_SESSIONS}`);
}

/** ***** Begin Public/Exported Functions ***** */

/**
 * Indicates whether authentication is required for the current run.
 *
 * Environment controls:
 * - AUTH_REQUIRED=true|false
 *
 * @returns {boolean} True when auth should be enforced.
 */
export function isAuthenticationRequired() {
  return AUTH_REQUIRED;
}

/**
 * Returns whether this Virtual User already has an authenticated session in this runtime.
 * @returns {boolean} True when this VU has already logged in.
 */
export function hasAuthenticatedVirtualUserSession() {
  return isVirtualUserAuthenticated;
}

/**
 * Builds a deterministic username for the active Virtual User.
 *
 * The username is constructed as: {PREFIX}-{SALT}-{VU_ID}
 * where SALT is a 3-digit per-process value that prevents username
 * collisions when multiple k6 instances run concurrently.
 *
 * @returns {string} Per-Virtual User username value.
 * @example
 *  When running any scenario with VU #3 and a process salt of 472:
 *  buildVirtualUserUsername() => "oels-vu-472-3"
 */
export function buildVirtualUserUsername() {
  const virtualUserId = execution.vu.idInTest ?? __VU;
  if (virtualUserId === undefined || virtualUserId === null) {
    fail('Unable to resolve a stable Virtual User ID for authentication username generation.');
  }
  return `${AUTH_USERNAME_PREFIX}-${_VU_INSTANCE_SALT}-${virtualUserId}`;
}

/**
 * Applies auth policy for the current Virtual User:
 * 1) Check whether auth is required for this run.
 * 2) Reuse existing VU session when already authenticated.
 * 3) Perform login when auth is required and session is not authenticated.
 *
 * @returns {string|null} Username when authenticated, otherwise null when auth is disabled.
 */
export function ensureAuthenticationIfRequired() {
  //logAuthConfig();

  if (!isAuthenticationRequired()) {
    logAuthDebug('Authentication not required for this run; skipping login.');
    return null;
  }

  const hasSessionCookie = hasApiScopeSessionCookie();
  if (hasSessionCookie) {
    if (!currentVirtualUserUsername) {
      currentVirtualUserUsername = buildVirtualUserUsername();
      logAuthDebug(`recovered username from stable VU id: ${currentVirtualUserUsername}`);
    }

    isVirtualUserAuthenticated = true;
    logAuthDebug(`reusing authenticated session for username=${currentVirtualUserUsername}`);
    return currentVirtualUserUsername;
  }

  if (hasAuthenticatedVirtualUserSession()) {
    logAuthDebug(`local auth state was true but JSESSIONID was missing. Re-authenticating username=${currentVirtualUserUsername || 'unknown'}`);
    isVirtualUserAuthenticated = false;
    currentVirtualUserUsername = null;
  }

  const username = buildVirtualUserUsername();
  const body = `j_username=${encodeURIComponent(username)}&j_password=${encodeURIComponent(AUTH_PASSWORD)}`;
  const loginUrl = `${BASE_URL}${AUTH_LOGIN_ENDPOINT}`;

  const res = http.post(loginUrl, body, {
    headers: FORM_URLENCODED_HEADERS,
    tags: { name: 'POST auth/login', resource: 'auth', op: 'login' },
    redirects: 0,
  });

  const ok = check(res, {
    [labelCheckName('default', 'auth login status valid')]: (r) => [200, 302, 303, 307].includes(r.status),
  });

  const cookieNames = Object.keys(res.cookies || {});
  const locationHeader = res.headers.Location || res.headers.location || '';
  const jsessionFromResponse = res.cookies?.JSESSIONID?.[0]?.value ? res.cookies.JSESSIONID[0].value.substring(0, 20) : 'N/A';
  
  logAuthDebug(`login: username=${username} status=${res.status} redirect=${locationHeader || '(none)'} cookies=${cookieNames.join(',') || '(none)'}`);
  logAuthDebug(`login: response JSESSIONID=${jsessionFromResponse}... from endpoint=${loginUrl}`);

  if (!ok) {
    captureFailureContext({
      failureType: 'auth_login_failure',
      failedChecks: [labelCheckName('default', 'auth login status valid')],
      response: res,
      metadata: {
        username,
        endpoint: AUTH_LOGIN_ENDPOINT,
      },
    });
    fail(`Authentication login failed for username=${username} with status=${res.status}, body=${res.body}`);
  }

  assertApiScopeSessionCookie(username);

  isVirtualUserAuthenticated = true;
  currentVirtualUserUsername = username;
  vuLastLoginTime = Date.now();
  return username;
}

/**
 * Backward-compatible alias for existing scripts.
 * @deprecated Prefer ensureAuthenticationIfRequired() for clearer auth policy intent.
 * @returns {string|null} Username when authenticated, otherwise null when auth is disabled.
 */
export function ensureVirtualUserAuthenticated() {
  return ensureAuthenticationIfRequired();
}

/**
 * Checks whether the active VU session has exceeded the configured duration and, if so,
 * runs the full invalidation cycle (invalidate endpoint → check endpoint → Tomcat logout).
 *
 * This is called once per iteration BEFORE ensureAuthenticationIfRequired() in the default
 * phase. When it returns true, the caller must end the iteration without running any business
 * logic. The next iteration will find no active session and perform a normal fresh login.
 *
 * When AUTH_SESSION_DURATION_SECONDS is 0 (the default), this function is a no-op.
 *
 * @returns {boolean} True when the session was invalidated and the iteration should end.
 *   False when no action was taken and the iteration should proceed normally.
 */
export function handleSessionDurationExpiry() {
  if (AUTH_SESSION_DURATION_SECONDS <= 0) return false;
  if (!isVirtualUserAuthenticated) return false;
  if (vuLastLoginTime <= 0) return false;
  if ((Date.now() - vuLastLoginTime) < AUTH_SESSION_DURATION_SECONDS * 1000) return false;

  logAuthDebug(`session-duration: username=${currentVirtualUserUsername} exceeded ${AUTH_SESSION_DURATION_SECONDS}s; running invalidation cycle.`);
  invalidateContextSession();
  return true;
}

/**
 * Validates the authenticated session by making a "ping" request.
 * @param {string} username - Authenticated username.
 * @note This should only be called from diagnostics/validation test suites, not load tests.
 */
export function validateAuthenticatedSession(username) {
  const pingTestUrl = `${BASE_URL}/devsuite/web/api/catalog/ping`;
  
  logAuthDebug(`session-validate: about to GET ${pingTestUrl}`);
  
  const res = http.get(pingTestUrl, {
    headers: { Accept: 'application/json' },
    tags: { name: 'GET auth/validate', resource: 'auth', op: 'validate' },
  });

  const ok = check(res, {
    [labelCheckName('default', 'auth session validation status ok')]: (r) => r.status === 200,
  });

  const cookieHeader = res.request.headers['Cookie'] || '(none)';
  logAuthDebug(`session-validate: username=${username} status=${res.status} url=${pingTestUrl} cookie-header=${cookieHeader}`);

  if (!ok) {
    captureFailureContext({
      failureType: 'auth_session_validation_failure',
      failedChecks: [labelCheckName('default', 'auth session validation status ok')],
      response: res,
      metadata: {
        username,
        endpoint: '/devsuite/web/api/catalog/ping',
      },
    });
    fail(
      `Authentication session validation failed for username=${username}. ` +
      `GET ${pingTestUrl} returned status=${res.status}. ` +
      `This indicates the authenticated session is not being sent with API requests.`
    );
  }
}

/**
 * Logs the active Virtual User session out.
 * 
 * This function:
 * 1. POSTs to the logout endpoint to invalidate the session server-side
 * 2. Clears the JSESSIONID cookie from the VU's cookie jar
 * 3. Resets the VU's authentication state
 * 
 * The cookie jar clearing ensures that even with AUTH_STICKY_SESSIONS=true,
 * the stale JSESSIONID won't be reused on subsequent iterations.
 */
export function logoutVirtualUserSession() {
  if (!isVirtualUserAuthenticated) {
    return;
  }

  const logoutUrl = `${BASE_URL}${AUTH_LOGOUT_ENDPOINT}`;
  const res = http.post(logoutUrl, '', {
    headers: FORM_URLENCODED_HEADERS,
    tags: { name: 'POST auth/logout', resource: 'auth', op: 'logout' },
    redirects: 0,
  });

  const ok = check(res, {
    [labelCheckName('default', 'auth logout status valid')]: (r) => [200, 302, 303, 307].includes(r.status),
  });

  const locationHeader = res.headers.Location || res.headers.location || '';
  logAuthDebug(`logout: username=${currentVirtualUserUsername || 'unknown'} status=${res.status} redirect=${locationHeader || '(none)'}`);
  logAuthDebug(`logout: endpoint=${AUTH_LOGOUT_ENDPOINT}`);

  if (!ok) {
    captureFailureContext({
      failureType: 'auth_logout_failure',
      failedChecks: [labelCheckName('default', 'auth logout status valid')],
      response: res,
      metadata: {
        username: currentVirtualUserUsername || 'unknown',
        endpoint: AUTH_LOGOUT_ENDPOINT,
      },
    });
    fail(`Authentication logout failed for username=${currentVirtualUserUsername || 'unknown'} with status=${res.status}, body=${res.body}`);
  }

  // Clear JSESSIONID from the cookie jar across all scopes where it may exist
  const jar = http.cookieJar();
  const cookieScopes = [AUTH_API_SCOPE_PATH, AUTH_COOKIE_SCOPE_PATH, AUTH_CONTEXT_PATH, '/'];
  
  for (const scope of cookieScopes) {
    const scopeUrl = `${BASE_URL}${scope}`;
    try {
      jar.delete(scopeUrl, AUTH_SESSION_COOKIE_NAME);
      logAuthDebug(`logout: cleared JSESSIONID from scope ${scope}`);
    } catch (e) {
      logAuthDebug(`logout: could not delete JSESSIONID from scope ${scope} (cookie may not exist)`);
    }
  }

  isVirtualUserAuthenticated = false;
  currentVirtualUserUsername = null;
}

/**
 * Performs the full context invalidation cycle for the active Virtual User session.
 *
 * This simulates the logout + re-login contention pattern observed in the customer
 * application. The sequence mirrors the production flow:
 *   1. Soft-invalidate the ABL context via GET /context/invalidate
 *      - marks the ContextDetail row as expired (sessionInvalidated = now)
 *   2. Verify the invalidation took hold via GET /context/check
 *      - expects HTTP 403; a 200 here means invalidation did not register
 *   3. Clear the Tomcat JSESSIONID via the existing logoutVirtualUserSession()
 *      - POST j_spring_security_logout + cookie jar clear + auth state reset
 *
 * After this call the VU is unauthenticated. The next call to
 * ensureAuthenticationIfRequired() will trigger a fresh login, which fires
 * the pre-login stale-session sweep (deleteContextsByUser) against the
 * now-invalidated row - generating the delete-vs-insert contention.
 *
 * No-op when the VU is not currently authenticated.
 */
export function invalidateContextSession() {
  if (!isVirtualUserAuthenticated) {
    logAuthDebug('invalidate: VU is not authenticated; skipping context invalidation cycle.');
    return;
  }

  const username = currentVirtualUserUsername || 'unknown';

  // Step 1: Soft-invalidate the ABL context.
  const invalidateUrl = `${BASE_URL}${AUTH_CONTEXT_API_PATH}/invalidate`;
  const invalidateRes = http.get(invalidateUrl, {
    headers: { Accept: 'application/json' },
    tags: { name: 'GET context/invalidate', resource: 'context', op: 'invalidate' },
  });

  const invalidateOk = check(invalidateRes, {
    [labelCheckName('default', 'context invalidate status ok')]: (r) => r.status === 200,
  });

  logAuthDebug(`invalidate: username=${username} status=${invalidateRes.status} url=${invalidateUrl}`);

  if (!invalidateOk) {
    captureFailureContext({
      failureType: 'auth_logout_failure',
      failedChecks: [labelCheckName('default', 'context invalidate status ok')],
      response: invalidateRes,
      metadata: { username, endpoint: invalidateUrl },
    });
    fail(`Context invalidation failed for username=${username} with status=${invalidateRes.status}, body=${invalidateRes.body}`);
  }

  // Log the invalidation timestamp returned by the server when available.
  try {
    const body = JSON.parse(invalidateRes.body);
    if (body && body.expired) {
      logAuthDebug(`invalidate: server recorded expiration at ${body.expired}`);
    }
  } catch (_) {
    // Non-JSON or missing body is not a failure; debug only.
  }

  // Step 2: Verify the invalidation is enforced - expect an error response.
  // The server returns _errorNum 403 in the body; the HTTP status may be 500 or 403.
  const checkUrl = `${BASE_URL}${AUTH_CONTEXT_API_PATH}/check`;
  const checkRes = http.get(checkUrl, {
    headers: { Accept: 'application/json' },
    tags: { name: 'GET context/check', resource: 'context', op: 'check' },
  });

  const checkOk = check(checkRes, {
    [labelCheckName('default', 'context check returned error')]: (r) => r.status === 403 || r.status === 500,
    [labelCheckName('default', 'context check error number 403')]: (r) => {
      try {
        const body = JSON.parse(r.body);
        return Array.isArray(body._errors) && body._errors.some((e) => Math.abs(e._errorNum) === 403);
      } catch (_) {
        return false;
      }
    },
  });

  logAuthDebug(`invalidate: context-check username=${username} status=${checkRes.status} url=${checkUrl}`);

  if (!checkOk) {
    captureFailureContext({
      failureType: 'auth_logout_failure',
      failedChecks: [labelCheckName('default', 'context check returned error')],
      response: checkRes,
      metadata: { username, endpoint: checkUrl },
    });
    fail(`Context invalidation verification failed for username=${username}: expected error response but got status=${checkRes.status}, body=${checkRes.body}`);
  }

  // Step 3: Clear the Tomcat JSESSIONID and reset VU auth state.
  logoutVirtualUserSession();

  logAuthDebug(`invalidate: full context invalidation cycle complete for username=${username}`);
}

/**
 * Executes a scenario function with optional auth lifecycle behavior.
 * @param {Function} scenarioFn - Test function to run after authentication.
 * @param {unknown} data - Scenario data passed to test function.
 */
export function runWithVirtualUserAuthentication(scenarioFn, data) {
  ensureAuthenticationIfRequired();

  // When the session duration limit is enabled (non-zero) and the elapsed time since the VU last
  // logged in meets or exceeds the configured duration, run the invalidation cycle as this
  // iteration's only work. The scenario function is skipped as this logic makes ~3 API calls
  // (invalidate, check, logout) as the VU's full turn. Re-login happens on the next iteration.
  if (AUTH_SESSION_DURATION_SECONDS > 0 && isVirtualUserAuthenticated &&
      vuLastLoginTime > 0 && (Date.now() - vuLastLoginTime) >= AUTH_SESSION_DURATION_SECONDS * 1000) {
    invalidateContextSession();
    return;
  }

  try {
    scenarioFn(data);
  } finally {
    if (AUTH_LOGOUT_EACH_ITERATION) {
      logoutVirtualUserSession();
    }
  }
}

/**
 * Runs only the authentication lifecycle for the current Virtual User.
 * @returns {{username: string}} Result summary.
 */
export function runAuthOnly() {
  const username = ensureAuthenticationIfRequired();

  if (!username) {
    fail('runAuthOnly requires authentication, but AUTH_REQUIRED is false.');
  }

  return { username };
}
