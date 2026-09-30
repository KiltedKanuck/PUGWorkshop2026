#!/bin/sh
#
# Custom environment variables for OELS testing.

# Append a lightweight marker each time this script is loaded.
OELS_SETENV_LOG="$(cd "$(dirname "${BASH_SOURCE:-$0}")" && pwd)/pug_setenv.log"
echo "$(date '+%Y-%m-%d %H:%M:%S %z') pug_setenv.sh executed (pid=$$, user=${USER:-unknown})" >> "${OELS_SETENV_LOG}" 2>/dev/null

# Provides sanity-checks via the /catalog/ping endpoint that custom environment variables are being loaded as expected:
export OELS_USE_CUSTOM_PING=true
if [ -n "${HOSTNAME:-}" ]; then
  export OELS_PING_HOST="${HOSTNAME}"
else
  export OELS_PING_HOST="$(hostname 2>/dev/null || uname -n)"
fi

(return 0 2>/dev/null) && return 0 || exit 0
