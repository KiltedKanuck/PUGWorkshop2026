# Test Execution Output and Debugging Logs

This document describes how k6 captures, routes, and persists test output during and after execution.

## Output Matrix (Native vs Custom)

Use this as the quick reference for what each output is, how it is produced, and who typically consumes it.

| Output | Artifact | Produced Via | Native to k6 | Output Frequency | Typical Consumers | Notes |
|---|---|---|---|---|---|---|
| Raw Metrics JSON | `results.json` | `--out json=...` | Yes | Streaming | Engineers, data pipelines, post-processing tools | Optional in launchers; enabled only when passing `-includeJsonResults`. Newline-delimited metric events/samples, not full request/response payload archives. |
| Aggregated Summary JSON | `summary.json` | `--summary-export=...` | Yes | End-of-run | CI scripts, engineers, reporting automation | Final aggregated metrics and threshold outcomes. |
| Console Output | `console.log` | `--console-output=...` | Yes | Streaming | Engineers debugging failures | Captures only the script console calls (`console.log/warn/error`), not every k6 engine/runtime line. |
| Dashboard HTML | `dashboard.html` | `K6_WEB_DASHBOARD=true` + `K6_WEB_DASHBOARD_EXPORT=...` | Yes | End-of-run | Engineers, QA, stakeholders | Optional in launchers; enabled only when passing `-useDashboard`. Visual report representing aggregated metrics from the same run. |
| Custom Summary Text | `summary.txt` | `handleSummary(data)` | Yes (API) | End-of-run | Engineers, CI logs | Script-defined artifact for a readable report that includes launcher, config file context, phase-separated check totals from `root_group`, and actual metric rates when available. |
| JUnit XML | `junit.xml` | `handleSummary(data)` | No (Custom) | End-of-run | Jenkins, Azure DevOps, GitHub test UIs | Standard CI test-result format, produced by custom transformation in script code. |

> Note: In this document and context of k6, "console" means JavaScript `console.log/warn/error` output from k6 scripts, while "terminal" means the k6 process stdout/stderr stream shown in the shell at runtime.

## What Current Launchers Do Today

Current launcher behavior writes one run folder per scenario/config/timestamp and produces:

| Output | Artifact | Enablement |
|---|---|---|
| Console Output | `logs/<scenario>/<config>/<timestamp>/console.log` | Automatic |
| Custom Summary Text | `logs/<scenario>/<config>/<timestamp>/summary.txt` | Automatic |
| JUnit XML | `logs/<scenario>/<config>/<timestamp>/junit.xml` | Automatic |
| Dashboard HTML (optional) | `logs/<scenario>/<config>/<timestamp>/dashboard.html` | `-useDashboard` |
| Aggregated Summary JSON (optional) | `logs/<scenario>/<config>/<timestamp>/summary.json` | `-useSummary` |
| Raw Metrics JSON (optional) | `logs/<scenario>/<config>/<timestamp>/results.json` | `-includeJsonResults` |

To enable raw metrics JSON output for a run, add `-includeJsonResults` to the launcher command.

> Custom summary outputs are intended for at-a-glance results (`summary.txt`) or automated checks (`junit.xml`). Runtime terminal output is not captured directly, though any exceptions will be sent to the `console.log` file.
