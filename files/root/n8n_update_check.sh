#!/bin/bash

IMAGE_NAME="n8nio/n8n"
UPDATE_SCRIPT="./update_docker.sh" # Script to update the image

# Fetch the manifest for the 'latest' tag from Docker Hub
echo "Checking for updates..."
LATEST_DIGEST=$(curl -s "https://registry.hub.docker.com/v2/repositories/$IMAGE_NAME/tags/latest" | jq -r '.images[0].digest')

if [[ -z "$LATEST_DIGEST" || "$LATEST_DIGEST" == "null" ]]; then
    echo "Error: Could not retrieve the latest digest from Docker Hub."
    exit 1
fi

# Find the tag associated with this digest
LATEST_VERSION=$(curl -s "https://registry.hub.docker.com/v2/repositories/$IMAGE_NAME/tags" | jq -r --arg DIGEST "$LATEST_DIGEST" '.results[] | select(.images[].digest == $DIGEST) | .na>

if [[ -z "$LATEST_VERSION" ]]; then
    echo "Error: Could not find a version tag matching the latest digest."
    exit 1
fi

echo "Latest version found online: $LATEST_VERSION"

# Get the version currently running
CURRENT_VERSION=$(docker inspect --format '{{index .Config.Labels "org.opencontainers.image.version"}}' $(docker ps --filter "ancestor=docker.n8n.io/$IMAGE_NAME" --format "{{.Image}}") >

if [[ -z "$CURRENT_VERSION" || "$CURRENT_VERSION" == "latest" ]]; then
    # The currently running version is 'latest'. Checking actual version...
    CURRENT_VERSION=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "^$IMAGE_NAME:" | awk -F':' '{print $2}' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1)
fi

if [[ -z "$CURRENT_VERSION" ]]; then
    echo "Error: No version of $IMAGE_NAME is currently running or pulled."
    CURRENT_VERSION="none"
else
    echo "Currently running local version: $CURRENT_VERSION"
fi

# Compare versions
if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
    echo "A newer version ($LATEST_VERSION) is available."
    echo "It is recommended to back up your data before updating."
    read -p "Do you want to run the update script now? (yes/no): " CONFIRM
    if [[ "$CONFIRM" == "yes" ]]; then
        echo "Starting update..."
        bash "$UPDATE_SCRIPT" "$LATEST_VERSION"
    else
        echo "Update canceled."
    fi
else
    echo "n8n is up to date!"
fi
