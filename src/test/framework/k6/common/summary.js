/*
 * Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
 */

function xmlEscape(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

function normalizeOutputDir(dir) {
  if (!dir || typeof dir !== 'string') {
    return 'custom';
  }

  return dir.replace(/\/+$/, '') || 'custom';
}

function buildThresholdRows(data) {
  const rows = [];
  const metrics = data && data.metrics ? data.metrics : {};

  for (const metricName of Object.keys(metrics)) {
    const metric = metrics[metricName] || {};
    const thresholds = metric.thresholds || {};

    for (const thresholdName of Object.keys(thresholds)) {
      const threshold = thresholds[thresholdName] || {};
      rows.push({
        metric: metricName,
        threshold: thresholdName,
        ok: threshold.ok === true,
      });
    }
  }

  return rows;
}

function normalizePhaseLabel(value) {
  const text = String(value || '').trim().toLowerCase();
  if (text === 'setup' || text === 'default' || text === 'teardown') {
    return text;
  }

  return 'other';
}

function detectCheckPhase(checkName, ancestorNames) {
  const names = Array.isArray(ancestorNames) ? ancestorNames : [];

  for (const name of names) {
    const phase = normalizePhaseLabel(name);
    if (phase !== 'other') {
      return phase;
    }
  }

  const label = String(checkName || '').trim();
  const prefix = label.split(':', 1)[0];
  return normalizePhaseLabel(prefix);
}

function buildCheckRows(data) {
  const rows = [];
  const rootGroup = data && data.root_group && typeof data.root_group === 'object' ? data.root_group : null;

  function walkGroup(group, ancestorNames) {
    if (!group || typeof group !== 'object') {
      return;
    }

    const nextAncestors = Array.isArray(ancestorNames) ? ancestorNames.slice() : [];
    if (typeof group.name === 'string' && group.name.trim().length > 0) {
      nextAncestors.push(group.name.trim());
    }

    for (const checkEntry of Array.isArray(group.checks) ? group.checks : []) {
      const passes = Number.isFinite(checkEntry?.passes) ? checkEntry.passes : 0;
      const fails = Number.isFinite(checkEntry?.fails) ? checkEntry.fails : 0;
      rows.push({
        phase: detectCheckPhase(checkEntry?.name, nextAncestors),
        name: String(checkEntry?.name || '').trim(),
        passes,
        fails,
        total: passes + fails,
      });
    }

    for (const childGroup of Array.isArray(group.groups) ? group.groups : []) {
      walkGroup(childGroup, nextAncestors);
    }
  }

  walkGroup(rootGroup, []);
  return rows;
}

function summarizeCheckRows(checkRows) {
  const summary = {
    total: { passes: 0, fails: 0, total: 0 },
    phases: {
      setup: { passes: 0, fails: 0, total: 0 },
      default: { passes: 0, fails: 0, total: 0 },
      teardown: { passes: 0, fails: 0, total: 0 },
      other: { passes: 0, fails: 0, total: 0 },
    },
  };

  for (const row of Array.isArray(checkRows) ? checkRows : []) {
    const phase = summary.phases[row.phase] ? row.phase : 'other';
    summary.phases[phase].passes += row.passes;
    summary.phases[phase].fails += row.fails;
    summary.phases[phase].total += row.total;

    summary.total.passes += row.passes;
    summary.total.fails += row.fails;
    summary.total.total += row.total;
  }

  return summary;
}

function resolveLauncherName(data, launcherName) {
  if (typeof launcherName === 'string' && launcherName.trim().length > 0) {
    return launcherName.trim();
  }

  if (data && data.options && data.options.tags && typeof data.options.tags.launcher === 'string' && data.options.tags.launcher.trim().length > 0) {
    return data.options.tags.launcher.trim();
  }

  return 'unknown';
}

function resolveConfigFileName() {
  if (typeof __ENV.CONFIG_FILE === 'string' && __ENV.CONFIG_FILE.trim().length > 0) {
    return __ENV.CONFIG_FILE.trim();
  }

  return 'default (CONFIG_FILE omitted)';
}

function formatCount(value) {
  return Number.isFinite(value) ? String(Math.trunc(value)) : 'n/a';
}

function formatPercent(value) {
  return Number.isFinite(value) ? `${(value * 100).toFixed(2)}%` : 'n/a';
}

function formatFailureRate(fails, total) {
  if (!Number.isFinite(fails) || !Number.isFinite(total) || total <= 0) {
    return 'n/a';
  }

  return formatPercent(fails / total);
}

function getMetricRateStats(metricName, metric) {
  const values = metric && metric.values && typeof metric.values === 'object' ? metric.values : {};
  let passes = Number.isFinite(values.passes) ? values.passes : null;
  let fails = Number.isFinite(values.fails) ? values.fails : null;

  // k6's `http_req_failed` is a boolean rate where `passes` means failed requests.
  // Swap labels so the summary aligns with expected request pass/fail semantics.
  if (metricName === 'http_req_failed' && passes !== null && fails !== null) {
    const requestFailed = passes;
    const requestPassed = fails;
    passes = requestPassed;
    fails = requestFailed;
  }

  const total = passes !== null || fails !== null
    ? (passes || 0) + (fails || 0)
    : (Number.isFinite(values.count) ? values.count : null);

  let rate = null;
  if (passes !== null && fails !== null && total !== null && total > 0) {
    rate = fails / total;
  }
  else if (metric && metric.type === 'rate' && Number.isFinite(values.rate)) {
    rate = values.rate;
  }

  return {
    passes,
    fails,
    total,
    rate,
  };
}

function formatMetricRateDetails(metricName, metric) {
  const stats = getMetricRateStats(metricName, metric);

  if (stats.rate === null && stats.passes === null && stats.fails === null && stats.total === null) {
    return '';
  }

  const parts = [];

  if (stats.passes !== null) {
    parts.push(`passes=${formatCount(stats.passes)}`);
  }

  if (stats.fails !== null) {
    parts.push(`fails=${formatCount(stats.fails)}`);
  }

  if (stats.total !== null) {
    parts.push(`total=${formatCount(stats.total)}`);
  }

  if (stats.rate !== null) {
    parts.push(`rate=${formatPercent(stats.rate)}`);
  }

  return parts.length > 0 ? ` | actual: ${parts.join(', ')}` : '';
}

/**
 * Extracts the stat name from a threshold expression string.
 * Examples: "p(90)<1500" → "p(90)", "avg<500" → "avg", "med<1000" → "med".
 * @param {string} threshold - Threshold expression string.
 * @returns {string|null} Stat name, or null if not parseable.
 */
function parseTrendStatName(threshold) {
  const match = /^([a-z_]+(?:\(\d+(?:\.\d+)?\))?)/.exec(String(threshold || ''));
  return match ? match[1] : null;
}

/**
 * Formats the actual observed value for a trend metric threshold.
 * Looks up the stat (e.g. p(90), avg) in metric.values and formats it,
 * appending "ms" when the metric contains time values.
 * @param {string} threshold - Threshold expression string, e.g. "p(90)<1500".
 * @param {object} metric - k6 metric object with values and contains fields.
 * @returns {string} Formatted detail string, e.g. " | actual: p(90)=342.15ms", or "" if unavailable.
 */
function formatTrendThresholdDetail(threshold, metric) {
  const statName = parseTrendStatName(threshold);
  if (!statName) {
    return '';
  }

  const values = metric && metric.values && typeof metric.values === 'object' ? metric.values : {};
  const value = values[statName];
  if (!Number.isFinite(value)) {
    return '';
  }

  const isTime = metric && metric.contains === 'time';
  const formatted = isTime ? `${value.toFixed(2)}ms` : value.toFixed(2);
  return ` | actual: ${statName}=${formatted}`;
}

function formatCheckNameForPhase(phase, name) {
  const safeName = String(name || '').trim();
  if (safeName.length === 0) {
    return safeName;
  }

  const escapedPhase = String(phase || '').replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  if (escapedPhase.length === 0) {
    return safeName;
  }

  const duplicatePrefixPattern = new RegExp(`^${escapedPhase}\\s*:\\s*`, 'i');
  return safeName.replace(duplicatePrefixPattern, '');
}

function buildSummaryText(data, thresholdRows, launcherName) {
  const launcher = resolveLauncherName(data, launcherName);
  const configFile = resolveConfigFileName();
  const metrics = data && data.metrics ? data.metrics : {};
  const checkRows = buildCheckRows(data);
  const checkSummary = summarizeCheckRows(checkRows);
  const testRunDurationMs = data && data.state && typeof data.state.testRunDurationMs === 'number'
    ? data.state.testRunDurationMs
    : null;
  const durationSeconds = testRunDurationMs === null ? 'unknown' : (testRunDurationMs / 1000).toFixed(3);
  const passed = thresholdRows.filter((row) => row.ok).length;
  const failed = thresholdRows.length - passed;
  const phaseOrder = ['setup', 'default', 'teardown', 'other'];

  const lines = [
    'k6 run summary',
    '',
    `launcher: ${launcher}`,
    `config_file: ${configFile}`,
    '',
    `duration_seconds: ${durationSeconds}`,
    '',
    `thresholds_total: ${thresholdRows.length}`,
    `thresholds_passed: ${passed}`,
    `thresholds_failed: ${failed}`,
    '',
    'checks:',
    `- total: passes=${formatCount(checkSummary.total.passes)}, fails=${formatCount(checkSummary.total.fails)}, total=${formatCount(checkSummary.total.total)}, rate=${formatFailureRate(checkSummary.total.fails, checkSummary.total.total)}`,
  ];

  for (const phase of phaseOrder) {
    const phaseSummary = checkSummary.phases[phase];
    lines.push(`- ${phase}: passes=${formatCount(phaseSummary.passes)}, fails=${formatCount(phaseSummary.fails)}, total=${formatCount(phaseSummary.total)}, rate=${formatFailureRate(phaseSummary.fails, phaseSummary.total)}`);
  }

  if (checkRows.length === 0) {
    lines.push('- none');
  }
  else {
    for (const row of checkRows) {
      const renderedName = formatCheckNameForPhase(row.phase, row.name);
      lines.push(`- ${row.phase}: ${renderedName} | passes=${formatCount(row.passes)}, fails=${formatCount(row.fails)}, total=${formatCount(row.total)}, rate=${formatFailureRate(row.fails, row.total)}`);
    }
  }

  lines.push('', 'abl_duration:');

  const ablBuckets = [
    { label: 'crud',  metricName: 'abl_duration_crud'  },
    { label: 'other', metricName: 'abl_duration_other' },
  ];

  let ablAnyRecorded = false;
  for (const bucket of ablBuckets) {
    const ablMetric = metrics[bucket.metricName];
    if (!ablMetric || !ablMetric.values || !Number.isFinite(ablMetric.values.avg)) {
      continue;
    }

    ablAnyRecorded = true;
    const v = ablMetric.values;
    const minMs  = Number.isFinite(v.min) ? `${v.min.toFixed(2)}ms`  : 'n/a';
    const avgMs  = Number.isFinite(v.avg) ? `${v.avg.toFixed(2)}ms`  : 'n/a';
    const maxMs  = Number.isFinite(v.max) ? `${v.max.toFixed(2)}ms`  : 'n/a';
    const p90Ms  = Number.isFinite(v['p(90)']) ? `${v['p(90)'].toFixed(2)}ms` : 'n/a';
    lines.push(`- ${bucket.label}: min=${minMs}, avg=${avgMs}, max=${maxMs}, p(90)=${p90Ms}`);
  }

  if (!ablAnyRecorded) {
    lines.push('- none (no server-timing headers received)');
  }

  lines.push('', 'thresholds:');

  if (thresholdRows.length === 0) {
    lines.push('- none');
  }
  else {
    const sortedThresholds = thresholdRows.slice().sort((a, b) => {
      if (a.metric < b.metric) { return -1; }
      if (a.metric > b.metric) { return 1; }
      if (a.threshold < b.threshold) { return -1; }
      if (a.threshold > b.threshold) { return 1; }
      return 0;
    });
    for (const row of sortedThresholds) {
      const metric = metrics[row.metric];
      const metricDetails = (metric && metric.type === 'trend')
        ? formatTrendThresholdDetail(row.threshold, metric)
        : formatMetricRateDetails(row.metric, metric);
      lines.push(`- [${row.ok ? 'PASS' : 'FAIL'}] ${row.metric} :: ${row.threshold}${metricDetails}`);
    }
  }

  return `${lines.join('\n')}\n`;
}

function buildJUnitXml(data, thresholdRows, launcherName) {
  const launcher = resolveLauncherName(data, launcherName);
  const durationSeconds = data && data.state && typeof data.state.testRunDurationMs === 'number'
    ? (data.state.testRunDurationMs / 1000)
    : 0;
  const failures = thresholdRows.filter((row) => !row.ok).length;

  const testCases = thresholdRows.length === 0
    ? [
        '  <testcase classname="k6.thresholds" name="no-thresholds-defined" time="0" />',
      ]
    : thresholdRows.map((row) => {
        const caseName = `${row.metric} :: ${row.threshold}`;
        if (row.ok) {
          return `  <testcase classname="k6.thresholds" name="${xmlEscape(caseName)}" time="0" />`;
        }

        return [
          `  <testcase classname="k6.thresholds" name="${xmlEscape(caseName)}" time="0">`,
          `    <failure message="Threshold failed">${xmlEscape(caseName)}</failure>`,
          '  </testcase>',
        ].join('\n');
      });

  const tests = thresholdRows.length === 0 ? 1 : thresholdRows.length;

  return [
    '<?xml version="1.0" encoding="UTF-8"?>',
    `<testsuite name="k6-thresholds-${xmlEscape(launcher)}" tests="${tests}" failures="${failures}" errors="0" skipped="0" time="${durationSeconds.toFixed(3)}">`,
    ...testCases,
    '</testsuite>',
    '',
  ].join('\n');
}

export function createHandleSummary(launcherName) {
  return function handleSummary(data) {
    const outputDir = normalizeOutputDir(__ENV.SUMMARY_DIR);
    const thresholds = buildThresholdRows(data);
    const summaryText = buildSummaryText(data, thresholds, launcherName);
    const junitXml = buildJUnitXml(data, thresholds, launcherName);

    return {
      [`${outputDir}/summary.txt`]: summaryText,
      [`${outputDir}/junit.xml`]: junitXml,
    };
  };
}

export const handleSummary = createHandleSummary('unknown');
