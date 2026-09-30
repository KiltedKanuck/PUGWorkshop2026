#!/usr/bin/env bash
# Runs launchProcedures.js with k6.
# Usage: ./launchProcedures.sh <config-file>
# Example: ./launchProcedures.sh configs/smoke-local.json

# Exit on error (-e), undefined variables (-u), and pipe failures (-o pipefail)
# This ensures the script fails fast and loudly instead of continuing with errors
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/bin/k6-common.sh"

k6_run_launcher "${SCRIPT_DIR}" "procedures" "launchProcedures.js" "configs/smoke-local.json" "$@"
