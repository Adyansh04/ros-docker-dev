#!/bin/bash
# scripts/publish.sh
# Automated publishing workflow for CI/CD

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DOCKER_HUB_USERNAME="${DOCKER_HUB_USERNAME}"
DOCKER_HUB_PASSWORD="${DOCKER_HUB_PASSWORD}"
BUILD_ALL="${BUILD_ALL:-true}"
PUSH_LATEST="${PUSH_LATEST:-true}"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u)
            DOCKER_HUB_USERNAME="$2"
            shift 2
            ;;
        -p)
            DOCKER_HUB_PASSWORD="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Validate required environment variables
if [ -z "$DOCKER_HUB_USERNAME" ] || [ -z "$DOCKER_HUB_PASSWORD" ]; then
    echo -e "${RED}Error: DOCKER_HUB_USERNAME and DOCKER_HUB_PASSWORD must be set${NC}"
    exit 1
fi

echo -e "${BLUE}🚀 Automated ROS Docker Image Publishing${NC}"
echo "========================================"
echo "Username: $DOCKER_HUB_USERNAME"
echo "Build All: $BUILD_ALL"
echo "Push Latest: $PUSH_LATEST"
echo ""

# Login to Docker Hub
echo -e "${YELLOW}Logging into Docker Hub...${NC}"
echo "$DOCKER_HUB_PASSWORD" | docker login -u "$DOCKER_HUB_USERNAME" --password-stdin

# Determine what to build
if [ "$BUILD_ALL" = "true" ]; then
    echo -e "${YELLOW}Building all configurations...${NC}"
    ./scripts/build-images.sh --username "$DOCKER_HUB_USERNAME" --all --push
else
    echo -e "${YELLOW}Building default configurations...${NC}"
    ./scripts/build-images.sh --username "$DOCKER_HUB_USERNAME" --push \
        humble-cpu humble-gpu jazzy-cpu jazzy-gpu
fi

# Tag and push latest versions if requested
if [ "$PUSH_LATEST" = "true" ]; then
    echo -e "${YELLOW}Pushing latest tags...${NC}"
    
    # Push general latest tag (point to humble-cpu as most common)
    docker tag "${DOCKER_HUB_USERNAME}/ros-dev:humble-cpu" "${DOCKER_HUB_USERNAME}/ros-dev:latest"
    docker push "${DOCKER_HUB_USERNAME}/ros-dev:latest"
    
    echo -e "${GREEN}✅ Latest tags pushed successfully${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Publishing completed successfully!${NC}"
echo ""
echo -e "${BLUE}Available images:${NC}"
echo "  docker pull ${DOCKER_HUB_USERNAME}/ros-dev:latest"
echo "  docker pull ${DOCKER_HUB_USERNAME}/ros-dev:humble-cpu"
echo "  docker pull ${DOCKER_HUB_USERNAME}/ros-dev:humble-gpu"
echo "  docker pull ${DOCKER_HUB_USERNAME}/ros-dev:jazzy-cpu"
echo "  docker pull ${DOCKER_HUB_USERNAME}/ros-dev:jazzy-gpu"
