# Swap File for AWS Linux

By default an AWS Linux AMI may not utilize a swap file or disk, but this is critical for emergency situations. Notably, if memory is exhausted too quickly the OOM-killer may not have time to react to kill processes, so keeping a local swap file on the root disk can allow for an emergency space where memory can be swapped and allow the system to respond.

## Install and Run

    chmod 775 bin/mkswap.sh
    sudo ./bin/mkswap.sh
