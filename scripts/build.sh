#!/bin/bash
# scripts/build.sh - Fixed build script with proper GPU handling

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
ROS_DISTRO="humble"
ENABLE_GPU="false"
CUDA_VERSION="12.2"
UBUNTU_VERSION=""
REBUILD="false"
PROFILE=""

usage() {
    echo -e "${BLUE}ROS Docker Development Environment Build Script${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -d, --distro DISTRO     ROS distro (noetic, humble, jazzy, kilted) [default: humble]"
    echo "  -g, --gpu               Enable NVIDIA GPU support"
    echo "  -c, --cuda VERSION      CUDA version [default: 12.2]"
    echo "  -u, --ubuntu VERSION    Ubuntu version [default: auto]"
    echo "  -r, --rebuild           Force rebuild (no cache)"
    echo "  -p, --profile PROFILE   Docker compose profile to use"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --distro humble --gpu --cuda 12.2"
    echo "  $0 --distro noetic --rebuild"
    echo "  $0 --profile jazzy"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--distro)
            ROS_DISTRO="$2"
            shift 2
            ;;
        -g|--gpu)
            ENABLE_GPU="true"
            shift
            ;;
        -c|--cuda)
            CUDA_VERSION="$2"
            shift 2
            ;;
        -u|--ubuntu)
            UBUNTU_VERSION="$2"
            shift 2
            ;;
        -r|--rebuild)
            REBUILD="true"
            shift
            ;;
        -p|--profile)
            PROFILE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Validate ROS distro and set Ubuntu version if not specified
case $ROS_DISTRO in
    noetic)
        UBUNTU_VERSION="${UBUNTU_VERSION:-20.04}"
        ;;
    humble)
        UBUNTU_VERSION="${UBUNTU_VERSION:-22.04}"
        ;;
    jazzy|kilted)
        UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}"
        ;;
    *)
        echo -e "${RED}Invalid ROS distro: $ROS_DISTRO${NC}"
        echo "Supported distros: noetic, humble, jazzy, kilted"
        exit 1
        ;;
esac

# Validate CUDA version
if [ "$ENABLE_GPU" = "true" ]; then
    case $CUDA_VERSION in
        11.8|12.0|12.1|12.2|12.3)
            echo -e "${GREEN}Using CUDA version: $CUDA_VERSION${NC}"
            ;;
        *)
            echo -e "${RED}Invalid CUDA version: $CUDA_VERSION${NC}"
            echo "Supported versions: 11.8, 12.0, 12.1, 12.2, 12.3"
            exit 1
            ;;
    esac
fi

# Create .env file with proper GPU runtime handling
echo -e "${YELLOW}Creating .env file...${NC}"
cat > .env << EOF
# ROS Configuration
ROS_DISTRO=$ROS_DISTRO
UBUNTU_VERSION=$UBUNTU_VERSION

# GPU Configuration
ENABLE_GPU=$ENABLE_GPU
CUDA_VERSION=$CUDA_VERSION

# Display Configuration
DISPLAY=$DISPLAY

# Docker Configuration
DOCKER_BUILDKIT=1
COMPOSE_PROJECT_NAME=ros-dev
EOF

# Set GPU runtime environment variables properly
if [ "$ENABLE_GPU" = "true" ]; then
    echo "GPU_RUNTIME=nvidia" >> .env
    echo "NVIDIA_VISIBLE_DEVICES=all" >> .env
    echo "NVIDIA_DRIVER_CAPABILITIES=all" >> .env
    echo -e "${GREEN}GPU support enabled with NVIDIA runtime${NC}"
else
    echo "GPU_RUNTIME=" >> .env
    echo "NVIDIA_VISIBLE_DEVICES=" >> .env
    echo "NVIDIA_DRIVER_CAPABILITIES=" >> .env
    echo -e "${BLUE}CPU-only mode${NC}"
fi

# Create workspace directories
echo -e "${YELLOW}Creating workspace directories...${NC}"
mkdir -p workspaces/ros_ws/src
mkdir -p workspaces/catkin_ws/src
mkdir -p workspaces/colcon_ws/src
mkdir -p docker

# Touch bash history file
touch docker/.bash_history

# Verify NVIDIA Docker runtime if GPU enabled
if [ "$ENABLE_GPU" = "true" ]; then
    echo -e "${YELLOW}Verifying NVIDIA Docker runtime...${NC}"
    if ! docker info | grep -q "nvidia"; then
        echo -e "${RED}Warning: NVIDIA Docker runtime not detected!${NC}"
        echo "Please install nvidia-docker2 or Docker with NVIDIA Container Runtime"
        echo "Continue anyway? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo -e "${GREEN}NVIDIA Docker runtime detected${NC}"
    fi
fi

# Build arguments
BUILD_ARGS=""
if [ "$REBUILD" = "true" ]; then
    BUILD_ARGS="--no-cache"
    echo -e "${YELLOW}Force rebuilding (no cache)...${NC}"
fi

# Profile arguments
PROFILE_ARGS=""
if [ -n "$PROFILE" ]; then
    PROFILE_ARGS="--profile $PROFILE"
    echo -e "${GREEN}Using profile: $PROFILE${NC}"
fi

# Display build information
echo -e "${YELLOW}Building ROS development environment...${NC}"
echo -e "${BLUE}Configuration:${NC}"
echo "  ROS Distro: $ROS_DISTRO"
echo "  Ubuntu Version: $UBUNTU_VERSION"
echo "  GPU Support: $ENABLE_GPU"
if [ "$ENABLE_GPU" = "true" ]; then
    echo "  CUDA Version: $CUDA_VERSION"
fi

# Run docker-compose build with proper arguments
echo -e "${YELLOW}Running docker-compose build...${NC}"
if ! docker-compose $PROFILE_ARGS build $BUILD_ARGS; then
    echo -e "${RED}Build failed!${NC}"
    echo "Check the logs above for errors"
    exit 1
fi

# Start the container
echo -e "${YELLOW}Starting container...${NC}"
if ! docker-compose $PROFILE_ARGS up -d; then
    echo -e "${RED}Failed to start container!${NC}"
    docker-compose logs ros-dev
    exit 1
fi

# Wait for container to be ready (with timeout)
echo -e "${YELLOW}Waiting for container to be ready...${NC}"
timeout=60
counter=0
container_ready=false

while [ $counter -lt $timeout ]; do
    if docker-compose ps | grep -q "ros-dev.*Up"; then
        container_ready=true
        break
    fi
    sleep 2
    counter=$((counter + 2))
    echo -n "."
done
echo ""

if [ "$container_ready" = false ]; then
    echo -e "${RED}Container failed to start within $timeout seconds${NC}"
    echo -e "${YELLOW}Container logs:${NC}"
    docker-compose logs ros-dev
    exit 1
fi

# Test ROS installation
echo -e "${YELLOW}Testing ROS installation...${NC}"
if [ "$ROS_DISTRO" = "noetic" ]; then
    if docker-compose exec -T ros-dev bash -c "source /opt/ros/noetic/setup.bash && rosversion -d" > /dev/null 2>&1; then
        echo -e "${GREEN}ROS1 Noetic installation verified${NC}"
    else
        echo -e "${RED}ROS1 Noetic installation test failed${NC}"
    fi
else
    if docker-compose exec -T ros-dev bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash && ros2 --version" > /dev/null 2>&1; then
        echo -e "${GREEN}ROS2 ${ROS_DISTRO} installation verified${NC}"
    else
        echo -e "${RED}ROS2 ${ROS_DISTRO} installation test failed${NC}"
    fi
fi

# Test GPU if enabled
if [ "$ENABLE_GPU" = "true" ]; then
    echo -e "${YELLOW}Testing GPU access...${NC}"
    if docker-compose exec -T ros-dev nvidia-smi > /dev/null 2>&1; then
        echo -e "${GREEN}GPU access verified${NC}"
    else
        echo -e "${RED}GPU access test failed${NC}"
    fi
fi

# Show final status
echo ""
echo -e "${GREEN}✅ Build completed successfully!${NC}"
echo ""
echo -e "${BLUE}Container status:${NC}"
docker-compose ps
echo ""
echo -e "${BLUE}Quick commands:${NC}"
echo "  Connect to container: ${YELLOW}docker-compose exec ros-dev bash${NC}"
echo "  Open in VS Code: ${YELLOW}code .${NC}"
echo "  View logs: ${YELLOW}docker-compose logs ros-dev${NC}"
echo "  Stop container: ${YELLOW}docker-compose down${NC}"
echo "  Run tests: ${YELLOW}./scripts/test.sh${NC}"
echo ""
echo -e "${BLUE}Test ROS installation:${NC}"
if [ "$ROS_DISTRO" = "noetic" ]; then
    echo "  ${YELLOW}docker-compose exec ros-dev roscore${NC}"
else
    echo "  ${YELLOW}docker-compose exec ros-dev ros2 node list${NC}"
fi
echo ""
echo -e "${BLUE}Build ROS workspaces:${NC}"
echo "  ${YELLOW}docker-compose exec ros-dev ros-build${NC}"
