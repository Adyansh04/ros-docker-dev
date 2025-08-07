#!/bin/bash
# scripts/build-images.sh
# Build and optionally push ROS Docker images to Docker Hub

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DOCKER_HUB_USERNAME="${DOCKER_HUB_USERNAME:-your-username}"
IMAGE_NAME_PREFIX="ros-dev"
PUSH_TO_HUB="false"
BUILD_ALL="false"
REBUILD="false"
TEST_AFTER_BUILD="true"

# Supported configurations
declare -A ROS_CONFIGS=(
    ["humble-cpu"]="humble false 12.2 22.04"
    ["humble-gpu"]="humble true 12.2 22.04"
    ["jazzy-cpu"]="jazzy false 12.9.1 24.04"        
    ["jazzy-gpu"]="jazzy true 12.9.1 24.04"           
    ["noetic-cpu"]="noetic false 11.8 20.04"
    ["noetic-gpu"]="noetic true 11.8 20.04"
    ["kilted-cpu"]="kilted false 12.9.1 24.04"      
    ["kilted-gpu"]="kilted true 12.9.1 24.04"       
)

usage() {
    echo -e "${BLUE}ROS Docker Image Builder${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS] [CONFIGS...]"
    echo ""
    echo "Options:"
    echo "  -u, --username USERNAME     Docker Hub username [default: \$DOCKER_HUB_USERNAME]"
    echo "  -p, --push                  Push images to Docker Hub after building"
    echo "  -a, --all                   Build all supported configurations"
    echo "  -r, --rebuild               Force rebuild (no cache)"
    echo "  -t, --no-test               Skip testing after build"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo "Available configurations:"
    for config in "${!ROS_CONFIGS[@]}"; do
        echo "  $config"
    done | sort
    echo ""
    echo "Examples:"
    echo "  $0 humble-cpu humble-gpu                # Build specific configs"
    echo "  $0 --all --push                         # Build and push all images"
    echo "  $0 --username myuser humble-cpu --push  # Build and push with custom username"
}

# Parse arguments
CONFIGS_TO_BUILD=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--username)
            DOCKER_HUB_USERNAME="$2"
            shift 2
            ;;
        -p|--push)
            PUSH_TO_HUB="true"
            shift
            ;;
        -a|--all)
            BUILD_ALL="true"
            shift
            ;;
        -r|--rebuild)
            REBUILD="true"
            shift
            ;;
        -t|--no-test)
            TEST_AFTER_BUILD="false"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
        *)
            CONFIGS_TO_BUILD+=("$1")
            shift
            ;;
    esac
done

# Validate Docker Hub username
if [ "$PUSH_TO_HUB" = "true" ] && [ -z "$DOCKER_HUB_USERNAME" ]; then
    echo -e "${RED}Error: Docker Hub username required for pushing${NC}"
    echo "Set DOCKER_HUB_USERNAME environment variable or use --username option"
    exit 1
fi

# Determine which configurations to build
if [ "$BUILD_ALL" = "true" ]; then
    CONFIGS_TO_BUILD=($(printf '%s\n' "${!ROS_CONFIGS[@]}" | sort))
elif [ ${#CONFIGS_TO_BUILD[@]} -eq 0 ]; then
    echo -e "${YELLOW}No configurations specified. Building default: humble-cpu${NC}"
    CONFIGS_TO_BUILD=("humble-cpu")
fi

# Function to build a single image
build_image() {
    local config="$1"
    local config_params="${ROS_CONFIGS[$config]}"
    
    if [ -z "$config_params" ]; then
        echo -e "${RED}Error: Unknown configuration '$config'${NC}"
        return 1
    fi
    
    # Parse configuration parameters
    read -r ros_distro enable_gpu cuda_version ubuntu_version <<< "$config_params"
    
    # Generate image tags
    local base_tag="${DOCKER_HUB_USERNAME}/${IMAGE_NAME_PREFIX}:${config}"
    local latest_tag="${DOCKER_HUB_USERNAME}/${IMAGE_NAME_PREFIX}:${ros_distro}-latest"
    
    echo -e "${BLUE}Building image: $config${NC}"
    echo "  ROS Distro: $ros_distro"
    echo "  GPU Support: $enable_gpu"
    echo "  CUDA Version: $cuda_version"
    echo "  Ubuntu Version: $ubuntu_version"
    echo "  Image Tag: $base_tag"
    
    # Create temporary .env for this build
    local temp_env=$(mktemp)
    cat > "$temp_env" << EOF
ROS_DISTRO=$ros_distro
ENABLE_GPU=$enable_gpu
CUDA_VERSION=$cuda_version
UBUNTU_VERSION=$ubuntu_version
DOCKER_BUILDKIT=1
EOF
    
    # Build arguments
    local build_args=""
    if [ "$REBUILD" = "true" ]; then
        build_args="--no-cache"
    fi
    
    # Build the image
    if docker build \
        $build_args \
        --build-arg ROS_DISTRO="$ros_distro" \
        --build-arg ENABLE_GPU="$enable_gpu" \
        --build-arg CUDA_VERSION="$cuda_version" \
        --build-arg UBUNTU_VERSION="$ubuntu_version" \
        -t "$base_tag" \
        -t "$latest_tag" \
        -f docker/compose/Dockerfile \
        .; then
        
        echo -e "${GREEN}✅ Successfully built: $base_tag${NC}"
        
        # Test the image if enabled
        if [ "$TEST_AFTER_BUILD" = "true" ]; then
            echo -e "${YELLOW}Testing image: $base_tag${NC}"
            if ./scripts/test-image.sh "$base_tag" "$ros_distro" "$enable_gpu"; then
                echo -e "${GREEN}✅ Image test passed: $base_tag${NC}"
            else
                echo -e "${RED}❌ Image test failed: $base_tag${NC}"
                rm -f "$temp_env"
                return 1
            fi
        fi
        
        # Push to Docker Hub if requested
        if [ "$PUSH_TO_HUB" = "true" ]; then
            echo -e "${YELLOW}Pushing to Docker Hub: $base_tag${NC}"
            if docker push "$base_tag" && docker push "$latest_tag"; then
                echo -e "${GREEN}✅ Successfully pushed: $base_tag${NC}"
            else
                echo -e "${RED}❌ Failed to push: $base_tag${NC}"
                rm -f "$temp_env"
                return 1
            fi
        fi
    else
        echo -e "${RED}❌ Failed to build: $base_tag${NC}"
        rm -f "$temp_env"
        return 1
    fi
    
    rm -f "$temp_env"
    return 0
}

# Main execution
echo -e "${YELLOW}🐳 Building ROS Docker Images${NC}"
echo "================================"

# Docker Hub login if pushing
if [ "$PUSH_TO_HUB" = "true" ]; then
    echo -e "${YELLOW}Logging into Docker Hub...${NC}"
    if ! docker login; then
        echo -e "${RED}Failed to login to Docker Hub${NC}"
        exit 1
    fi
fi

# Build statistics
TOTAL_BUILDS=0
SUCCESSFUL_BUILDS=0
FAILED_BUILDS=0

# Build each configuration
for config in "${CONFIGS_TO_BUILD[@]}"; do
    TOTAL_BUILDS=$((TOTAL_BUILDS + 1))
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Building configuration: $config ($TOTAL_BUILDS/${#CONFIGS_TO_BUILD[@]})${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if build_image "$config"; then
        SUCCESSFUL_BUILDS=$((SUCCESSFUL_BUILDS + 1))
    else
        FAILED_BUILDS=$((FAILED_BUILDS + 1))
        echo -e "${RED}Failed to build $config${NC}"
    fi
done

# Build summary
echo ""
echo -e "${YELLOW}📊 Build Summary${NC}"
echo "=================="
echo -e "Total builds: ${BLUE}$TOTAL_BUILDS${NC}"
echo -e "Successful: ${GREEN}$SUCCESSFUL_BUILDS${NC}"
echo -e "Failed: ${RED}$FAILED_BUILDS${NC}"

if [ $FAILED_BUILDS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 All images built successfully!${NC}"
    
    if [ "$PUSH_TO_HUB" = "true" ]; then
        echo ""
        echo -e "${GREEN}📦 Images available on Docker Hub:${NC}"
        for config in "${CONFIGS_TO_BUILD[@]}"; do
            echo "  docker pull ${DOCKER_HUB_USERNAME}/${IMAGE_NAME_PREFIX}:${config}"
        done
    fi
    
    exit 0
else
    echo -e "${RED}❌ Some builds failed. Check the logs above.${NC}"
    exit 1
fi
