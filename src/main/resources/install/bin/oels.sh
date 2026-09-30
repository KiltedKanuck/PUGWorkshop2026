#!/bin/bash
# Shell Management Tool

PROG=`basename $0`

# Utility must be run with DLC environment variable set
if [ ! -d $DLC/ant ]
then
    echo "Progress DLC path may not be set correctly."
    echo "Please run from within a PROENV session."
    echo
    exit 1
fi

# Set the java environment via java_env; requires DLC
if [ ! -f $DLC/bin/java_env ]
then
    echo "Progress $PROG Messages:"
    echo
    echo "java_env could not be found."
    echo
    echo "JAVA environment not set correctly."
    echo
    exit 1
fi

# Set the JAVA environment
. $DLC/bin/java_env

# Build the Apache Ant execution script path
ANTSCRIPT=${ANTSCRIPT-$DLC/ant/bin/ant}

if [ ! -f $ANTSCRIPT ]
then
    echo "Progress $PROG Messages:"
    echo
    echo "The OpenEdge Apache Ant launch script could not be found."
    echo
    echo "Progress DLC path may not be set correctly."
    echo "Please run from within a PROENV session."
    echo
    echo "Progress DLC setting: $DLC"
    echo "Script not found: $ANTSCRIPT"
    echo
    exit 1
fi

# Initialize local variables
WRITE_ACCESS_WARNING_TRIGGERED=false

# Function to test write access
test_write_access() {
    if [ ! -e "$1" ]; then
        echo "WARNING: File '$1' does not exist."
        return 1
    fi

    if [ ! -w "$1" ]; then
        echo "WARNING: You do not have write access to '$1' which is required for registering the PASOE instance."
        echo "SOLUTION: Please request that your system administrator grant you write access, or run the script with elevated privileges (e.g., using sudo)."

        # Set variable to indicate warning was triggered
        WRITE_ACCESS_WARNING_TRIGGERED=true
        return 1
    fi

    # Do not exit, but allow the script to continue with the info above. If you do want to exit just uncomment the line below:
    #return 1
    return 0
}

# Run the check
CHECK_FILE="$DLC/servers/pasoe/conf/instances.unix"
test_write_access "$CHECK_FILE"

# Prefix arguments with a "-D" as necessary. This allows the user to pass parameters
# without the prefix (if they forgot) and allows the task name to be anywhere within
# the list of arguments passed to this script. Note that multiple tasks may be run,
# in the order by which they are given.
TASKARGS=()
for arg in "$@"; do
    if [[ "$arg" == *"="* ]] && [[ "$arg" != "-D"* ]]; then
        # Split on the first '=' to separate key and value
        key="${arg%%=*}"
        value="${arg#*=}"

        # If value contains spaces and isn't already quoted, add quotes
        if [[ "$value" == *" "* ]] && [[ ! ("$value" == \"*\" || "$value" == \'*\') ]]; then
            taskArg="-D${key}=\"${value}\""
        else
            taskArg="-D$arg"
        fi
    else
        taskArg="$arg"
    fi

    TASKARGS="$TASKARGS $taskArg"
done

# Add a special writeAccessWarning parameter if write access warning was detected at the OS level.
if [ "$WRITE_ACCESS_WARNING_TRIGGERED" = "true" ]; then
    TASKARGS="$TASKARGS -DwriteAccessWarning=true"
fi

# Detect hardware resources and pass them as properties to the Ant tasks.

# CPU count: prefer nproc, fall back to counting /proc/cpuinfo entries, default to 1.
CPU_COUNT=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 1)

# Total memory: read MemTotal from /proc/meminfo (in kB), convert to whole MB, default to 0.
TOTAL_MEM_KB=$(awk '/MemTotal/{print $2}' /proc/meminfo 2>/dev/null || echo 0)
TOTAL_MEM_MB=$(( TOTAL_MEM_KB / 1024 ))

# Hostname: use the hostname command, universally available on Linux/Unix.
SYSTEM_HOSTNAME=$(hostname)

# Append detected values to the task arguments for Ant.
TASKARGS="$TASKARGS -DsystemCpuCount=$CPU_COUNT -DsystemMemorySize=$TOTAL_MEM_MB -DsystemHostname=$SYSTEM_HOSTNAME"

# Set any remaining environment variables needed for Ant.
ANT_HOME=$DLC/ant ; export ANT_HOME
SCRIPT_HOME=$(dirname "$0")

# Echo the command that will be executed (for debugging/transparency).
#echo "Executing: \"$ANTSCRIPT\" -f \"$SCRIPT_HOME/<script>.xml\" $TASKARGS"

# Uses the XML as task instructions to Ant, passing all task arguments.
SCRIPT_NAME="$(basename "$0")"
exec "$ANTSCRIPT" -f "$SCRIPT_HOME/${SCRIPT_NAME%.*}.xml" $TASKARGS
