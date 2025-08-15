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
CONTAINER_NAME="ros_${DISTRO}_dev"

echo "Running container ${CONTAINER_NAME} from image ${IMAGE_NAME}:${TAG}"

# IMPORTANT: Before running this script, you must allow local connections
# to the X server on your host machine by running:
# xhost +local:docker

docker run -it --rm \
    --name "${CONTAINER_NAME}" \
    --runtime=nvidia \
    --gpus all \
    --privileged \
    --net=host \
    --env-file "./${DISTRO}/env.list" \
    -e "DISPLAY" \
    -v "/tmp/.X11-unix:/tmp/.X11-unix:rw" \
    "${IMAGE_NAME}:${TAG}"

echo "Container exited."