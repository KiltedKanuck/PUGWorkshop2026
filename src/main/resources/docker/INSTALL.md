# Installing Docker CE/CLI

This guide provides the one-time instructions for installing Docker CE and the Docker CLI. The container image is built for use with Ubuntu Linux, which builds from a standard Grafana k6 image. You can install and run Docker directly on Ubuntu, or on Windows or macOS through a sandboxed Ubuntu Linux installation.


## Example Docker CE Installation (Windows 11)

This example installation demonstrates using the **Windows Subsystem for Linux (WSL2)** with **Docker CE** on a Windows 11 host OS. Windows 10 may still work, but it is near end-of-life and is not the preferred setup. This process only needs to be followed once per Windows installation where the container will be run. Once these steps are completed you may continue to the **Starting Docker Services** section.


### Windows Prerequisite: Install WSL 2 with Ubuntu

The following assumes you have not yet installed WSL2 on your Windows environment. You may still proceed with the following steps anyway to ensure all components are installed and available.

1. Open a PowerShell session as Administrator:

    * Press `Win + X`
    * Click `PowerShell (Admin)` or `Terminal (Admin)`

    Alternatively, double-click on the "PowerShell (Admin)" shortcut provided in this directory.

2. Navigate (change directory) to the folder where the `install_wsl.ps1` script resides and execute the script (note the backslash is intentional):

        .\install_wsl.ps1

    If your Windows environment disallows running scripts you may need to execute with the following command:

        powershell -ExecutionPolicy Bypass -File install_wsl.ps1

3. A new window will be opened to a terminal session in your Ubuntu instance. Follow the prompts to create a new user account with its own password.

4. In the original PowerShell terminal, set Ubuntu to be the default kernel when starting WSL:

        wsl --set-default Ubuntu

    Confirm by using the following to check for an asterisk "*" next to the distribution name:

        wsl --list --verbose

5. Continue from the [**Install Docker CE/CLI (Ubuntu Linux)**](#install-docker-cecli-ubuntu-linux) steps below to install the necessary Docker packages in Linux.


## Install Docker CE/CLI (Ubuntu Linux)

Follow these common instructions for installing **Docker Community Edition (CE)** and the **Docker Command-Line Interface (CLI)** on an Ubuntu installation. This may be a standalone OS image running directly on x86_64 hardware, a virtual machine, or Windows Subsystem for Linux (WSL2). This only needs to be performed once on the host OS.

1. Navigate (change directory) to the folder where the extracted `pug-<version>-client-docker` directory exists.

    Please note for a WSL environment:

    * If you extracted the archive in `C:\Downloads\pug-<version>-client-docker` use `cd /mnt/c/Downloads/pug-<version>-client-docker`
    * The name `/mnt/c` is your `C:` drive, `/mnt/d` for the `D:` drive, etc.

2. Execute the installation script with the help of `sudo` (note the forward slash is intentional):

        sudo ./install_docker.sh

3. Start the Docker service and check the status:

    sudo service docker restart
    sudo service docker status

4. Return to the **Starting Docker Images** section of the [README](README.md#starting-docker-images) document to continue with the OELS k6 client container image.

**Note:** It may be necessary to restart your WSL environment after installing the Docker components:

- Press `CTRL+D` to exit the Ubuntu session, repeating that key combination until you get back to the PowerShell terminal.
- Enter `wsl --shutdown` followed by `wsl -d Ubuntu` to restart Ubuntu.


## Starting Docker Services

### Starting Docker (for Windows via WSL)

If using Windows you must first start WSL.

1. If you have not yet opened a PowerShell terminal, do so as Administrator:

    * Press `Win + X`
    * Click `PowerShell (Admin)` or `Terminal (Admin)`

2. If you are not yet running Ubuntu, open this in WSL 2:

        wsl -d Ubuntu

3. Continue at the **Starting Docker (Linux)** steps below.


### Starting Docker (Linux)

From within a Linux (Ubuntu) installation perform the following steps:

1. Confirm if the Docker service is running:

        sudo service docker status

    **Note:** It may be necessary to press `q` or `CTRL+C` to exit the status display.

2. Start Docker manually if it **is not** running:

        sudo service docker restart

3. You may use the "status" command in the first step to confirm whether the Docker service was started successfully.

4. Continue with the [Starting Docker Images instructions in the README](README.md#starting-docker-images) file.

