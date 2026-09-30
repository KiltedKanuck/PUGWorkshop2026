# EARLYOOM - Early Out-Of-Memory Watchdog

By default the OOM-killer in the Linux kernel may respond too slowly to an impending low-memory situation.

Installing the "earlyoom" package solves that by proactively monitoring memory and swap space for problems.
The steps below will install and configure for when memory is below 5% (-m 5) or swap is below 5% (-s 5).

## Install the earlyoom package

    sudo apt update
    sudo apt install -y earlyoom

## Activate and configure earlyoom

    sudo systemctl enable --now earlyoom
    echo 'EARLYOOM_ARGS="-m 5 -s 5 --avoid '\''sshd|systemd|systemd-journald'\''"' | sudo tee /etc/default/earlyoom
    cat /etc/default/earlyoom

## Restart and check status

    sudo systemctl restart earlyoom
    ps aux | grep earlyoom
    systemctl status earlyoom
