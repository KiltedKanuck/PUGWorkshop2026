#!/bin/sh
#
# Custom environment variables for OELS load suite testing.

# Append a lightweight marker each time this script is loaded.
OELS_SETENV_LOG="$(cd "$(dirname "${BASH_SOURCE:-$0}")" && pwd)/oels_setenv.log"
echo "$(date '+%Y-%m-%d %H:%M:%S %z') oels_setenv.sh executed (pid=$$, user=${USER:-unknown})" >> "${OELS_SETENV_LOG}" 2>/dev/null

# Provides sanity-checks via the /catalog/ping endpoint that custom environment variables are being loaded as expected:
export OELS_USE_CUSTOM_PING=true
if [ -n "${HOSTNAME:-}" ]; then
  export OELS_PING_HOST="${HOSTNAME}"
else
  export OELS_PING_HOST="$(hostname 2>/dev/null || uname -n)"
fi

# Comma-delimited list of ABL application names that should use the context manager:
export CONTEXT_MANAGED_ABLAPPS="LoadSuite"

# Force use of the original context logic from customer application code:
export USE_ORIGINAL_CONTEXT_LOGIC=true

# Force an explicit delete of the user context object rather than dereferencing:
#export USE_EXPLICIT_CONTEXT_DELETE=true

(return 0 2>/dev/null) && return 0 || exit 0
