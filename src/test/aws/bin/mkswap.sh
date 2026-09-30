#!/usr/bin/env bash
# mkswap.sh - Run as "sudo ./mkswap.sh"

# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error.
# Ensure failures in pipelines are properly detected.
set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# Path to the swap file we want to create/manage.
SWAPFILE="/swapfile"

# Size of the swap file (recommended: 8GB file for 16GB+ memory).
# Examples:
#   4G = 4 gigabytes
#   8G = 8 gigabytes
SWAPSIZE="8G"

# Swappiness controls how aggressively Linux prefers swapping.
# Lower values = avoid swap unless memory pressure is severe.
#
# Typical server recommendations:
#   5-10  = emergency swap only
#   60    = common desktop default
SWAPPINESS="10"

# sysctl configuration file for persistent swappiness setting.
SYSCTL_CONF="/etc/sysctl.d/99-swappiness.conf"

# -----------------------------------------------------------------------------
# Root/Sudo Check
# -----------------------------------------------------------------------------

# Swap management requires root privileges.
if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: This script must be run as root or with sudo."
    exit 1
fi

# -----------------------------------------------------------------------------
# Check Whether Swap Already Exists
# -----------------------------------------------------------------------------

# swapon --show lists active swap devices/files.
# We grep specifically for our desired swap file path.
if swapon --show | grep -q "^${SWAPFILE}"; then
    echo "Swap file already active: ${SWAPFILE}"
else
    echo "Swap file is not currently active."

    # -------------------------------------------------------------------------
    # Create Swap File If Missing
    # -------------------------------------------------------------------------

    if [[ ! -f "${SWAPFILE}" ]]; then
        echo "Creating swap file: ${SWAPFILE}"
        echo "Requested swap size: ${SWAPSIZE}"

        # fallocate quickly reserves disk space for the file.
        #
        # -l specifies the length/size of the file.
        #
        # Example:
        #   fallocate -l 4G /swapfile
        #
        # creates a 4 GB file.
        fallocate -l "${SWAPSIZE}" "${SWAPFILE}"

        # Restrict permissions so only root can read/write.
        #
        # Linux requires swap files to not be world-readable.
        chmod 600 "${SWAPFILE}"

        # Format the file as swap space.
        #
        # mkswap initializes the file so Linux can use it for swapping.
        mkswap "${SWAPFILE}"

        echo "Swap file created successfully."
    else
        echo "Swap file already exists on disk."
        echo "Skipping creation step."
    fi

    # -------------------------------------------------------------------------
    # Enable Swap File
    # -------------------------------------------------------------------------

    echo "Enabling swap file..."

    # swapon enables the swap device/file immediately.
    swapon "${SWAPFILE}"

    echo "Swap file enabled."
fi

# -----------------------------------------------------------------------------
# Persist Swap File Across Reboots
# -----------------------------------------------------------------------------

# /etc/fstab controls filesystems and swap entries mounted at boot.
#
# We only add the entry if it does not already exist.
if ! grep -q "^${SWAPFILE}" /etc/fstab; then
    echo "Adding swap entry to /etc/fstab for persistence."

    # Entry format:
    #
    # <file>     none    swap    sw    0    0
    #
    # sw = default swap mount options
    echo "${SWAPFILE} none swap sw 0 0" >> /etc/fstab
else
    echo "Swap entry already present in /etc/fstab"
fi

# -----------------------------------------------------------------------------
# Configure Swappiness
# -----------------------------------------------------------------------------

echo "Setting vm.swappiness to ${SWAPPINESS}"

# Write the persistent sysctl configuration.
#
# sysctl settings stored in /etc/sysctl.d/*.conf
# are automatically loaded during boot.
echo "vm.swappiness=${SWAPPINESS}" > "${SYSCTL_CONF}"

# Apply the setting immediately without rebooting.
sysctl -p "${SYSCTL_CONF}"

# -----------------------------------------------------------------------------
# Validation
# -----------------------------------------------------------------------------

echo
echo "--------------------------------------------------"
echo "Validation"
echo "--------------------------------------------------"

echo
echo "Active swap devices/files:"
swapon --show

echo
echo "Memory summary:"
free -h

echo
echo "Current swappiness value:"
cat /proc/sys/vm/swappiness

echo
