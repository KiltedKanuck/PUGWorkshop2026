#!/bin/bash
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="${SCRIPT_DIR}/instance_started.log"
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
# Ensure job control is enabled
#
if ! shopt -o monitor | grep -q on; then
    echo "Warning: 'monitor' shell option is OFF. Enabling it to ensure proper job control."
    set -o monitor
fi

#
# Start the database for the PAS instance.
#
export DBNAME=@DBNAME@
export DBHOST=@DBHOST@
export DBPORT=@DBPORT@
export MINPORT=@MINPORT@
export MAXPORT=@MAXPORT@
export CODEPAGE=@CODEPAGE@
export ENTRDBMS=@ENTERPRISE_RDBMS@

# Load database startup options from the instance bin directory.
DBOPTS_CONFIG_PATH="${SCRIPT_DIR}/dboptions.properties"
DB_OPTION_SPECS=(
    "bibufs:-bibufs"
    "B:-B"
    "L:-L"
    "Mm:-Mm"
    "Ma:-Ma"
    "Mpb:-Mpb"
    "Mi:-Mi"
    "Mn:-Mn"
    "n:-n"
    "semsets:-semsets"
    "Mxs:-Mxs"
    "hash:-hash"
    "aibufs:-aibufs"
    "Bpmax:-Bpmax"
    "aiarcinterval:-aiarcinterval"
    "bithold:-bithold"
    "Mf:-Mf"
)

# Enterprise RDBMS-only options (only added if ENTRDBMS is true)
if [ "${ENTRDBMS}" = "true" ]; then
    DB_OPTION_SPECS+=(
        "lruskips:-lruskips"
        "spin:-spin"
    )
fi
DB_FLAG_SPECS=(
    "aistall:-aistall"
    "bistall:-bistall"
    "directio:-directio"
)
STARTUP_PROCESS_SPECS=(
    "bim:PROBIM_CMD"
    "aiw:PROAIW_CMD"
    "biw:PROBIW_CMD"
)

get_property() {
    local file_path="$1"
    local property_name="$2"
    local property_regex
    if [ ! -f "${file_path}" ]; then
        return 1
    fi

    property_regex=${property_name//./\\.}
    grep -E "^[[:space:]]*${property_regex}[[:space:]]*=" "${file_path}" | tail -n 1 | sed -E 's/^[^=]*=[[:space:]]*//; s/[[:space:]]+$//'
}

has_property() {
    local file_path="$1"
    local property_name="$2"
    local property_regex
    if [ ! -f "${file_path}" ]; then
        return 1
    fi

    property_regex=${property_name//./\\.}
    grep -Eq "^[[:space:]]*${property_regex}([[:space:]]*=.*)?$" "${file_path}"
}

if [ -f "${DBOPTS_CONFIG_PATH}" ]; then
    echo "Loaded DB options from ${DBOPTS_CONFIG_PATH} (unset keys are omitted)."
else
    echo "DB options config not found at ${DBOPTS_CONFIG_PATH}. Optional db options and process startups are omitted."
fi

append_switch_if_present() {
    local switch_name="$1"
    local property_value="$2"
    if [ -n "${property_value}" ]; then
        DBOPTS="${DBOPTS} ${switch_name} ${property_value}"
    fi
}

DBOPTS=""
for spec in "${DB_OPTION_SPECS[@]}"; do
    property_name=${spec%%:*}
    switch_name=${spec#*:}
    property_value=$(get_property "${DBOPTS_CONFIG_PATH}" "dbopt.${property_name}")
    append_switch_if_present "${switch_name}" "${property_value}"
done

for spec in "${DB_FLAG_SPECS[@]}"; do
    property_name=${spec%%:*}
    switch_name=${spec#*:}
    if has_property "${DBOPTS_CONFIG_PATH}" "dbopt.${property_name}"; then
        DBOPTS="${DBOPTS} ${switch_name}"
    fi
done

DBOPTS="${DBOPTS} -minport ${MINPORT} -maxport ${MAXPORT}"
DBOPTS="${DBOPTS# }"
export DBOPTS

#
# Set common variables for utilities
#
PROUTIL_CMD="${DLC}/bin/proutil"
PROSERV_CMD="${DLC}/bin/proserve"
PROWDOG_CMD="${DLC}/bin/prowdog"
PROBIM_CMD="${DLC}/bin/probim"
PROAIW_CMD="${DLC}/bin/proaiw"
PROBIW_CMD="${DLC}/bin/probiw"
PROAPW_CMD="${DLC}/bin/proapw"

APW_COUNT=$(get_property "${DBOPTS_CONFIG_PATH}" "dbopt.apw")
if [ -z "${APW_COUNT}" ]; then
    APW_COUNT="0"
elif [[ ! "${APW_COUNT}" =~ ^[0-9]+$ ]]; then
    echo "Ignoring invalid dbopt.apw value '${APW_COUNT}' (expected integer)."
    APW_COUNT="0"
fi

# Common parameters
DB_PATH="${DBDIR}/${DBNAME}.db"
CODEPAGE_ARGS="-cpinternal ${CODEPAGE} -cpstream ${CODEPAGE}"

#
# Check if the database is already in use (and take appropriate action)
#
"${PROUTIL_CMD}" "${DB_PATH}" -C holder
retcode=$? # this saves the return code
case $retcode in
0) echo "Starting database ${DBNAME} on port ${DBPORT}"
echo "Running: ${PROSERV_CMD} \"${DB_PATH}\" -H ${DBHOST} -S ${DBPORT} -N TCP -ipver IPv4 ${DBOPTS} ${CODEPAGE_ARGS}"
"${PROSERV_CMD}" "${DB_PATH}" -H ${DBHOST} -S ${DBPORT} -N TCP -ipver IPv4 ${DBOPTS} ${CODEPAGE_ARGS} > "${TEMPDIR}/dbstart.log" 2>&1
;;
14) echo "The database is in single-user mode"
exit $retcode
;;
16) echo "The database is in multi-user mode"
exit $retcode
;;
*) echo "proutil -C holder failed"
echo error code = $retcode
exit $retcode
;;
esac # case $retcode in

#
# Confirm if the database was started before starting other processes
# Retry up to 5 times with 1-second intervals, looking for return code 16
#
retry_count=0
max_retries=5
retcode=-1

while [ $retry_count -lt $max_retries ]; do
    "${PROUTIL_CMD}" "${DB_PATH}" -C holder
    retcode=$? # this saves the return code

    echo "Attempt $((retry_count + 1))/${max_retries}: proutil returned code $retcode"

    case $retcode in
    16) echo "Database is ready - Starting watchdog and AIW/BIW/APW processes for ${DBNAME}"
    "${PROWDOG_CMD}" "${DB_PATH}" ${CODEPAGE_ARGS}

    for spec in "${STARTUP_PROCESS_SPECS[@]}"; do
        property_name=${spec%%:*}
        command_name=${spec#*:}
        if has_property "${DBOPTS_CONFIG_PATH}" "dbopt.${property_name}"; then
            "${!command_name}" "${DB_PATH}" ${CODEPAGE_ARGS}
        fi
    done

    if [[ "${APW_COUNT}" =~ ^[0-9]+$ ]] && [ "${APW_COUNT}" -gt 0 ]; then
        apw_index=0
        while [ "${apw_index}" -lt "${APW_COUNT}" ]; do
            "${PROAPW_CMD}" "${DB_PATH}" ${CODEPAGE_ARGS}
            apw_index=$((apw_index + 1))
        done
    fi
    break # Exit the retry loop on success
    ;;
    0) echo "Return code 0: Database has not been started (will retry)"
    ;;
    *) echo "proutil -C holder returned an unexpected code: $retcode (will retry)"
    ;;
    esac

    retry_count=$((retry_count + 1))

    # If we haven't reached the desired state and have more retries left, wait
    if [ $retcode -ne 16 ] && [ $retry_count -lt $max_retries ]; then
        echo "Waiting 1 second before retry..."
        sleep 1
    fi
done

# If we exhausted all retries without getting return code 16, handle the final state
if [ $retcode -ne 16 ]; then
    case $retcode in
    0) echo "The database could not be started after $max_retries attempts"
    ;;
    14) echo "The database is in single-user mode after $max_retries attempts"
    ;;
    *) echo "proutil -C holder failed after $max_retries attempts with error code $retcode"
    ;;
    esac
    exit $retcode
fi

# Explicitly exit, gracefully
exit 0
