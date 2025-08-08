#!/bin/bash
# scripts/test-image.sh
# Test a specific ROS Docker image using temporary containers

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
IMAGE_TAG="$1"
ROS_DISTRO="$2"
ENABLE_GPU="${3:-false}"
CONTAINER_NAME="ros-test-$(date +%s)"

# Validation
if [ -z "$IMAGE_TAG" ]; then
    echo -e "${RED}Usage: $0 <image_tag> <ros_distro> [enable_gpu]${NC}"
    echo "Example: $0 username/ros-dev:humble-cpu humble false"
    exit 1
fi

echo -e "${BLUE}🧪 Testing ROS Docker Image${NC}"
echo "Image: $IMAGE_TAG"
echo "ROS Distro: $ROS_DISTRO"
echo "GPU Support: $ENABLE_GPU"
echo "Container: $CONTAINER_NAME"
echo ""

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${YELLOW}Testing: $test_name${NC}"
    xhost +local:root    
    if docker exec "$CONTAINER_NAME" bash -c "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS: $test_name${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL: $test_name${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Cleanup function
cleanup() {
    echo -e "${YELLOW}Cleaning up test container...${NC}"
    docker rm -f "$CONTAINER_NAME" > /dev/null 2>&1 || true
}

# Set trap for cleanup
trap cleanup EXIT

# Start test container
echo -e "${YELLOW}Starting test container...${NC}"

# Docker run arguments
DOCKER_ARGS="-d --name $CONTAINER_NAME -e ROS_DISTRO=$ROS_DISTRO -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix:rw"
# Add GPU support if enabled
if [ "$ENABLE_GPU" = "true" ]; then
    DOCKER_ARGS="$DOCKER_ARGS --runtime=nvidia --gpus=all"
    DOCKER_ARGS="$DOCKER_ARGS -e NVIDIA_VISIBLE_DEVICES=all"
    DOCKER_ARGS="$DOCKER_ARGS -e NVIDIA_DRIVER_CAPABILITIES=all"
fi

# Start container
if ! docker run $DOCKER_ARGS "$IMAGE_TAG" tail -f /dev/null; then
    echo -e "${RED}Failed to start test container${NC}"
    exit 1
fi

# Wait for container to be ready
sleep 5

# Basic system tests
echo -e "${BLUE}Running basic system tests...${NC}"
run_test "Container is running" "echo 'Container alive'"
run_test "Basic shell commands" "ls /workspace"
run_test "Git available" "git --version"
run_test "Python available" "python3 --version"
run_test "CMake available" "cmake --version"

# ROS-specific tests
echo -e "${BLUE}Running ROS tests...${NC}"
if [ "$ROS_DISTRO" = "noetic" ]; then
    run_test "ROS1 environment" "source /opt/ros/noetic/setup.bash && echo \$ROS_DISTRO"
    run_test "roscore available" "source /opt/ros/noetic/setup.bash && which roscore"
    run_test "rosmsg available" "source /opt/ros/noetic/setup.bash && which rosmsg"
    run_test "catkin_make available" "which catkin_make"
else
    run_test "ROS2 environment" "source /opt/ros/${ROS_DISTRO}/setup.bash && echo \$ROS_DISTRO"
    run_test "ros2 command available" "source /opt/ros/${ROS_DISTRO}/setup.bash && ros2 --help"
    run_test "colcon available" "which colcon"
fi

# Development tools tests
echo -e "${BLUE}Running development tools tests...${NC}"
run_test "GDB debugger" "gdb --version"
run_test "Valgrind" "valgrind --version"
run_test "Development aliases" "bash -i -c 'alias ll'"

# GPU tests (if enabled)
if [ "$ENABLE_GPU" = "true" ]; then
    echo -e "${BLUE}Running GPU tests...${NC}"
    run_test "NVIDIA SMI" "nvidia-smi"
    run_test "CUDA compiler" "nvcc --version"
    run_test "GPU environment variables" "echo \$NVIDIA_VISIBLE_DEVICES"
fi

# Workspace tests
echo -e "${BLUE}Running workspace tests...${NC}"
run_test "ROS workspace structure" "test -d /workspace/ros_ws/src"
run_test "Catkin workspace structure" "test -d /workspace/catkin_ws/src"
run_test "Colcon workspace structure" "test -d /workspace/colcon_ws/src"

# Build system tests
echo -e "${BLUE}Running build system tests...${NC}"
if [ "$ROS_DISTRO" = "noetic" ]; then
    run_test "Catkin workspace build" "cd /workspace/catkin_ws && source /opt/ros/noetic/setup.bash && catkin_make"
else
    run_test "Colcon workspace build" "cd /workspace/colcon_ws && source /opt/ros/${ROS_DISTRO}/setup.bash && colcon build"
fi

# Third-party library installation tests
echo -e "${BLUE}Running third-party library installation tests...${NC}"
run_test "Simd library installed" "test -d /workspace/third_party/Simd"
run_test "Simd headers available" "test -f /workspace/third_party/Simd/src/Simd/SimdLib.h"
run_test "xsimd library installed" "test -d /workspace/third_party/xsimd"
run_test "xsimd headers available" "test -f /workspace/third_party/xsimd/include/xsimd/xsimd.hpp"

# GUI and ROS2 demo tests (only for ROS2 distros)
if [ "$ROS_DISTRO" != "noetic" ]; then
    echo -e "${BLUE}Running GUI and ROS2 demo tests...${NC}"
    run_test "rqt_graph launches" "source /opt/ros/${ROS_DISTRO}/setup.bash && timeout 10s rqt_graph --help"
    run_test "rviz2 launches" "source /opt/ros/${ROS_DISTRO}/setup.bash && timeout 10s rviz2 --help"
    run_test "demo_nodes_cpp talker runs" "source /opt/ros/${ROS_DISTRO}/setup.bash && timeout 10s ros2 launch demo_nodes_cpp talker_listener.launch.py "
fi

# Test summary
echo ""
echo -e "${YELLOW}📊 Test Results${NC}"
echo "================"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Image is ready for use.${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Image may have issues.${NC}"
    exit 1
fi
