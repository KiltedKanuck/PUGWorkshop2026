#!/bin/bash
# update_image.sh
# This script removes and reloads a docker container image
# Performs cleanup of any persistent volumes from old apps

set -e # Exit on error

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root or use sudo" >&2
    exit 1
fi

# Remove any existing image by ane expected repository name
echo "Cleaning up Docker images for repository: pug/k6*"
docker images --format '{{.Repository}} {{.ID}}' --filter=reference='pug/k6*' | \
awk '{ print $2 }' | \
xargs -r docker rmi -f
echo "Cleanup complete."

# Load the current image archive
echo "Loading Docker image from archive..."
docker image load --input pug-k6-latest.tar

# Report current images registered
echo "Available Docker images:"
docker images

echo ""
echo "Image load complete. Next step: start the interactive shell"
echo "  sudo docker compose run --rm --service-ports k6-client sh"
echo ""
echo "While a test is running, open the live dashboard in your browser:"
echo "  http://localhost:5665"
echo ""
echo "Or use the shortcut file from within this folder:"
echo "  Open k6 Dashboard.url"

