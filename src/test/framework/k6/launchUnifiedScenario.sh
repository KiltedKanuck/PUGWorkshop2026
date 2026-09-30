#!/usr/bin/env bash
# Runs launchUnifiedScenario.js with k6.
# Usage: ./launchUnifiedScenario.sh <config-file>
# Example: ./launchUnifiedScenario.sh configs/smoke-local.json

# To execute the script directly (eg. for debugging) use the following command.
# Note: The path to the config file is relative to the script location (../configs).
# Example:
#   k6 run --log-format raw --console-output=logs/console.log \
#     --env SUMMARY_DIR=logs --env CONFIG_FILE=../configs/smoke-local.json \
#     scripts/launchUnifiedScenario.js

# Exit on error (-e), undefined variables (-u), and pipe failures (-o pipefail)
# This ensures the script fails fast and loudly instead of continuing with errors
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/bin/k6-common.sh"

STATUS_SCRIPT="${SCRIPT_DIR}/scripts/monitor/status.js"
DB_SCRIPT="${SCRIPT_DIR}/scripts/monitor/database.js"
SUMMARY_DIR="${SCRIPT_DIR}/logs"
mkdir -p "${SUMMARY_DIR}"

# Build monitor run args; forward BASE_URL from the environment if set.
MONITOR_ARGS=(run --log-format raw --env "SUMMARY_DIR=${SUMMARY_DIR}")
if [[ -n "${BASE_URL:-}" ]]; then
  MONITOR_ARGS+=(--env "BASE_URL=${BASE_URL}")
fi

# Pre-test snapshots.
k6 "${MONITOR_ARGS[@]}" "${STATUS_SCRIPT}"
k6 "${MONITOR_ARGS[@]}" "${DB_SCRIPT}"

# Main test run. Capture exit code so post-test snapshots always run.
main_exit=0
k6_run_launcher "${SCRIPT_DIR}" "unified" "launchUnifiedScenario.js" "configs/smoke-local.json" "$@" || main_exit=$?

# Post-test snapshots (always run, even if the main test failed).
k6 "${MONITOR_ARGS[@]}" "${STATUS_SCRIPT}"
k6 "${MONITOR_ARGS[@]}" "${DB_SCRIPT}"

exit $main_exit
