# OpenEdge Dev Suite

### Containerized k6 Client Overview

This document outlines the process necessary to run the **OpenEdge Dev Suite (OELS)** k6 client as a container. The recommended workflow is to start the container only when you need it, open an interactive shell, run Grafana k6 tests against a remote OELS server instance, and then exit so the container is removed automatically.


### Assumptions

For this approach it is possible to use any container orchestrator (eg. Docker, Rancher, etc.) which can run a Linux container. However, the Docker Desktop may not be allowed in an enterprise environment without a valid license. The following guide focuses on use of the community edition.

- A machine (real or virtual) with either Windows 11 (or Windows 10 with 22H2 service pack) or Ubuntu Linux.
- A local machine with a CPU capable of executing x86_64 binaries (the ARM architecture is not supported).


### Prerequisites

- For desktop use, a Windows 11 installation.
- For server use, an Ubuntu Linux installation.
- System memory of at least 4GB available to the host OS where the tooling will run.
- The container image as distributed and downloaded as a ZIP archive file.


### Notes

- This provides a local k6 runtime environment with pre-built k6 tests and sample configurations.
- The k6 client runs tests against remote PASOE servers - it does not include a server component.
- Test configuration files in the `configs/` directory define target servers and test parameters.


## Installing Docker

If you do not have Docker CE and the Docker CLI installed on the machine where you intend to run the OELS k6 tooling, please follow the [INSTALL](INSTALL.md) guide for OS-specific instructions. Otherwise, if you have already installed Docker, continue to the **Starting Docker Images** section to confirm the service is available and ready to run the container on demand.


## Starting Docker Images

Please [start the local Docker service](INSTALL.md#starting-docker-services) if it is not yet started. If already started you may continue to the appropriate section below to either load a container image or start a container.

- [**Container Image Deployment**](#container-image-deployment) - If you need to load or reload an OELS k6 container image
- [**Docker Container Startup**](#docker-container-startup) - If you simply need to start an existing OELS k6 container on demand


## Container Image Deployment

The following steps will extract the image from the downloaded archive and ensure you load the latest image. Please follow this process for any subsequent updates to the container, when and if they become available.

1. Locate the `pug-<version>-k6-client-docker.zip` archive downloaded and move to a preferred location.

2. Extract `pug-<version>-k6-client-docker.zip` into its own directory which should contain the following folders:

        configs -- Sample configuration files (auto-populated on first run)
        logs    -- k6 test results and output logs

    The following special files should also be visible:

        docker-compose.yaml   -- The configuration file for Docker
        INSTALL.md            -- Docker installation instructions
        README.md             -- This file :)
        Open k6 Dashboard.url -- Double-click to open the live dashboard in your browser
        pug-k6-latest.tar    -- The latest container image for Docker

3. Open a terminal session (for Linux), or start PowerShell (for Windows) and execute `wsl -d Ubuntu`.

4. Navigate (change directory) to the folder where the extracted ZIP file's contents exists.

    Please note for a WSL environment:

    * If you extracted the archive in `C:\Downloads\pug-<version>-k6-client-docker` use `cd /mnt/c/Downloads/pug-<version>-k6-client-docker`
    * The name `/mnt/c` is your `C:` drive, `/mnt/d` for the `D:` drive, etc.

5. **Note:** If you are updating an existing image, make sure no OELS k6 container is currently running before continuing. Exit the interactive shell to terminate the container.

6. Run the following script to first check (and remove) any existing OELS k6 image and then load the latest image from `pug-k6-latest.tar`:

        sudo ./update_image.sh

    You may see a message `Error response from daemon: No such image: pug/k6:<version>`; this is normal and expected the first time you load the image.

7. Verify that the container image was loaded correctly by examining the output of the previous command which should provide output similar to the text below:

        REPOSITORY          TAG        IMAGE ID        CREATED        SIZE
        pug/k6           1.0.0      <hex_id_string> <timestamp>     148MB

8. Continue to the [**Docker Container Startup**](#docker-container-startup) steps below.


## Docker Container Startup

The k6 client container is designed for **interactive use**. Start it when needed, run commands inside the shell, and exit when you are done so Docker can remove the container automatically.

### Interactive Shell (Recommended)

1. Start an interactive shell session in the k6 container:

    sudo docker compose run --rm --service-ports k6-client sh

2. Once inside the container (at `/opt/k6/tests`), you can:

        ls                           # List available tests and configs
        cat docs/README.md           # View test documentation
        ls configs/                  # View available configuration files

        # Run a test scenario (this sends 1 request to confirm the server will respond):
        ./launchUnifiedScenario.sh configs/smoke-local.json

        # Analyze results:
        view the file at html/latest-k6-dashboard.html

        # Exit when done:
        exit

3. The `configs/` and `docs/` directories are refreshed each time the container starts (copying from `configs.samples/` and `docs.local/`).
   Missing files are copied, and files are updated when the baked-in sample is newer.
   User-only files are preserved.

4. While a test is running, open your host browser to view the live k6 dashboard:

        http://localhost:5665

    Optional shortcut file from the extracted Docker support folder:

        Open k6 Dashboard.url

5. Test results are written to `logs/`, and the exported dashboard HTML is written to `html/latest-k6-dashboard.html`.

    Log Folder Structure: `logs/<scenario-name>/<config-name>/<time-started>/<file>`

### Non-Interactive (Automation)

Run a specific test directly without entering the shell:

    sudo docker compose run --rm --service-ports k6-client ./launchUnifiedScenario.sh configs/smoke-local.json

**Note:** The `configs/`, `docs/`, `html/`, and `logs/` directories are mounted from your host machine, so any changes made inside the container are immediately visible on your host filesystem.


## Troubleshooting

- If you get an error such as `no configuration file provided` make sure you have changed into the extracted directory where the `docker-compose.yaml` was extracted.
- If you see permission errors when copying configs, this is expected on Windows/WSL mounts and can be ignored - the files are still copied successfully.
- If tests fail to connect to your PASOE server, verify the server URLs in your `configs/*.json` files.
- Check the `logs/` directory for detailed k6 test output and results.
- Check `html/latest-k6-dashboard.html` for the latest exported dashboard report.


## Exiting the Container

When using the interactive shell:

1. Type `exit` or press `CTRL+D` to leave the container.
2. The container is automatically removed when you exit (due to the `--rm` flag).



## Docker/WSL Uninstall

If you wish to completely remove the Docker images and related components to fully reset your environment, please see the [UNINSTALL guide](UNINSTALL.md).

