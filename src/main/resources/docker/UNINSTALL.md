# Containerized Deployment Uninstall

This brief guide will instruct you on the process of removing your WSL environment on your Windows machine. This may be useful if you no longer wish to utilize this deployment option, or need to complete the installation process from the very beginning.

## WSL Reset (Windows Only, Optional)

If you are using Windows and wish to start completely from scratch you can delete your Ubuntu instance and re-install using WSL. Use the following commands to shutdown the current instance, unregister it, re-install, and confirm availability.

1. First exit any running Ubuntu session using `CTRL + D` or `exit <enter>` then shut down the WSL environment:

    wsl --shutdown

2. Remove the Ubuntu kernel from the WSL:

    wsl --unregister Ubuntu

3. Confirm removal of Ubuntu from WSL:

    wsl --list --verbose

4. While in a PowerShell (Admin) session you may completely remove WSL using the following:

    dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart

5. You should restart your Windows machine to complete the removal process.

Once the local WSL installation has been reset and removed you can re-install by following the [INSTALL guide](INSTALL.md).

