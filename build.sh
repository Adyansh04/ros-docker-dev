#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Check if a distro name is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <distro_name>"
    echo "Example: $0 humble"
    exit 1
fi

DISTRO=$1
IMAGE_NAME="ros-dev"
TAG="${DISTRO}"

echo "Building Docker image: ${IMAGE_NAME}:${TAG}"
echo "Context: ./${DISTRO}"

# Build the docker image
docker build -t "${IMAGE_NAME}:${TAG}" ./${DISTRO}

echo "Build complete. Image: ${IMAGE_NAME}:${TAG}"