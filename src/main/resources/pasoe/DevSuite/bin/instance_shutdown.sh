#!/bin/bash
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="${SCRIPT_DIR}/instance_shutdown.log"
exec >> "${LOGFILE}" 2>&1

if [ -z "${DLC}" ] ; then
    export DLC="@DLCHOME@"
fi

if [ -z "${CATALINA_BASE}" ]; then
    echo "CATALINA_BASE is not set, using static path."
    export CATALINA_BASE="@PASPATH@"
fi

if [ -z "${DBDIR}" ] ; then
    export DBDIR="${CATALINA_BASE}/db"
fi

if [ -z "${TEMPDIR}" ] ; then
    export TEMPDIR="${CATALINA_BASE}/temp"
fi

#
# Set database parameters
#
export DBNAME=@DBNAME@

#
# Stop the database for the PAS instance.
#
echo "Shutting down ${DBNAME} database."
PROSHUT_CMD="${DLC}/bin/proshut"
"${PROSHUT_CMD}" -by "${DBDIR}/${DBNAME}.db"

# Explicitly exit, gracefully
exit 0
