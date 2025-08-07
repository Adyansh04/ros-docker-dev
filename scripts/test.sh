#!/bin/bash
# scripts/test.sh - Comprehensive testing script for ROS development environment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_exit_code="${3:-0}"
    
    echo -e "${BLUE}Testing: $test_name${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$test_command" > /dev/null 2>&1; then
        local exit_code=$?
        if [ $exit_code -eq $expected_exit_code ]; then
            echo -e "${GREEN}✅ PASS: $test_name${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}❌ FAIL: $test_name (exit code: $exit_code, expected: $expected_exit_code)${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        echo -e "${RED}❌ FAIL: $test_name (command failed)${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Function to run container test
run_container_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_exit_code="${3:-0}"
    
    echo -e "${BLUE}Testing: $test_name${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if docker-compose exec -T ros-dev bash -c "$test_command" > /dev/null 2>&1; then
        local exit_code=$?
        if [ $exit_code -eq $expected_exit_code ]; then
            echo -e "${GREEN}✅ PASS: $test_name${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}❌ FAIL: $test_name (exit code: $exit_code, expected: $expected_exit_code)${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        echo -e "${RED}❌ FAIL: $test_name (command failed)${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Load environment
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}Error: .env file not found. Run ./scripts/build.sh first.${NC}"
    exit 1
fi

echo -e "${YELLOW}🧪 Running ROS Docker Development Environment Tests${NC}"
echo -e "${BLUE}Configuration:${NC}"
echo "  ROS Distro: ${ROS_DISTRO}"
echo "  GPU Enabled: ${ENABLE_GPU}"
echo ""

# ==========================================
# Docker and Container Tests
# ==========================================
echo -e "${YELLOW}📦 Docker and Container Tests${NC}"

run_test "Docker daemon running" "docker info"
run_test "Docker Compose available" "docker-compose --version"
run_test "Container exists" "docker-compose ps | grep -q ros-dev"
run_test "Container is running" "docker-compose ps | grep -q 'ros-dev.*Up'"

# ==========================================
# Basic System Tests
# ==========================================
echo -e "${YELLOW}🖥️  Basic System Tests${NC}"

run_container_test "Basic shell access" "echo 'Hello World'"
run_container_test "Workspace directory exists" "test -d /workspace"
run_container_test "Git available" "git --version"
run_container_test "Python3 available" "python3 --version"
run_container_test "CMake available" "cmake --version"

# ==========================================
# ROS Installation Tests
# ==========================================
echo -e "${YELLOW}🤖 ROS Installation Tests${NC}"

if [ "$ROS_DISTRO" = "noetic" ]; then
    # ROS1 Noetic tests
    run_container_test "ROS1 environment sourced" "test -n \"\$ROS_DISTRO\""
    run_container_test "ROS1 core tools available" "which roscore"
    run_container_test "ROS1 package tools available" "which rospack"
    run_container_test "ROS1 node tools available" "which rosnode"
    run_container_test "catkin_make available" "which catkin_make"
    run_container_test "rosdep available" "rosdep --version"
else
    # ROS2 tests
    run_container_test "ROS2 environment sourced" "test -n \"\$ROS_DISTRO\""
    run_container_test "ROS2 core tools available" "ros2 --help"
    run_container_test "ROS2 node command available" "ros2 node --help"
    run_container_test "ROS2 pkg command available" "ros2 pkg --help"
    run_container_test "colcon available" "colcon --help"
    run_container_test "rosdep available" "rosdep --version"
fi

# ==========================================
# Development Tools Tests
# ==========================================
echo -e "${YELLOW}🛠️  Development Tools Tests${NC}"

run_container_test "GDB debugger available" "gdb --version"
run_container_test "Valgrind available" "valgrind --version"
run_container_test "Git available" "git --version"
run_container_test "Vim editor available" "vim --version"
run_container_test "htop available" "which htop"
run_container_test "Custom build script available" "which ros-build"

# ==========================================
# Python Development Tests
# ==========================================
echo -e "${YELLOW}🐍 Python Development Tests${NC}"

run_container_test "pip3 available" "pip3 --version"
run_container_test "pytest available" "python3 -m pytest --version"
run_container_test "black formatter available" "python3 -m black --version"
run_container_test "flake8 linter available" "python3 -m flake8 --version"
run_container_test "numpy available" "python3 -c 'import numpy; print(numpy.__version__)'"

# ==========================================
# Simulation Tools Tests
# ==========================================
echo -e "${YELLOW}🎮 Simulation Tools Tests${NC}"

if [ "$ROS_DISTRO" = "noetic" ]; then
    run_container_test "Gazebo available" "gazebo --version"
    run_container_test "RViz available" "which rviz"
else
    run_container_test "RViz2 available" "which rviz2"
    run_container_test "Gazebo packages available" "ros2 pkg list | grep gazebo"
fi

# ==========================================
# GPU Tests (if enabled)
# ==========================================
if [ "$ENABLE_GPU" = "true" ]; then
    echo -e "${YELLOW}🎯 GPU Tests${NC}"
    
    run_container_test "NVIDIA runtime available" "nvidia-smi"
    run_container_test "CUDA available" "nvcc --version"
    run_container_test "GPU environment variables set" "test -n \"\$NVIDIA_VISIBLE_DEVICES\""
    run_container_test "OpenGL libraries available" "glxinfo | grep -q 'OpenGL'"
fi

# ==========================================
# Workspace Tests
# ==========================================
echo -e "${YELLOW}📁 Workspace Tests${NC}"

run_container_test "ROS workspace exists" "test -d /workspace/ros_ws/src"
run_container_test "Catkin workspace exists" "test -d /workspace/catkin_ws/src"
run_container_test "Colcon workspace exists" "test -d /workspace/colcon_ws/src"

# Test workspace building
if [ "$ROS_DISTRO" = "noetic" ]; then
    run_container_test "Catkin workspace can be built" "cd /workspace/catkin_ws && catkin_make"
else
    run_container_test "Colcon workspace can be built" "cd /workspace/colcon_ws && colcon build"
fi

# ==========================================
# Configuration Tests
# ==========================================
echo -e "${YELLOW}⚙️  Configuration Tests${NC}"

run_test "Environment file exists" "test -f .env"
run_test "Workspace directories exist" "test -d workspaces"
run_test "Config directory exists" "test -d config"
run_test "Scripts directory exists" "test -d scripts"

# ==========================================
# Integration Tests
# ==========================================
echo -e "${YELLOW}🔗 Integration Tests${NC}"

# Test ROS package creation and building
if [ "$ROS_DISTRO" = "noetic" ]; then
    run_container_test "Can create ROS1 package" "cd /workspace/catkin_ws/src && catkin_create_pkg test_package std_msgs rospy roscpp"
    run_container_test "Can build ROS1 package" "cd /workspace/catkin_ws && catkin_make"
else
    run_container_test "Can create ROS2 package" "cd /workspace/colcon_ws/src && ros2 pkg create test_package --build-type ament_cmake"
    run_container_test "Can build ROS2 package" "cd /workspace/colcon_ws && colcon build --packages-select test_package"
fi

# ==========================================
# Test Summary
# ==========================================
echo ""
echo -e "${YELLOW}📊 Test Summary${NC}"
echo "=================="
echo -e "Total Tests: ${BLUE}$TOTAL_TESTS${NC}"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Environment is ready for development.${NC}"
    exit 0
else
    echo -e "${RED}❌ $TESTS_FAILED test(s) failed. Please check the issues above.${NC}"
    exit 1
fi
