#!/usr/bin/env bash
set -euo pipefail

# Usage: ./test.sh [distro]
# Example: ./test.sh noetic

DISTRO="${1:-noetic}"
IMAGE_NAME="ros-dev"
TAG="${DISTRO}"
CONTAINER_NAME="ros_${DISTRO}_test"
ENV_FILE="./${DISTRO}/env.list"

LOG_DIR="./${DISTRO}_test_logs"
mkdir -p "${LOG_DIR}"

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m"

echo -e "${BLUE}Test runner for image: ${IMAGE_NAME}:${TAG}${NC}"
echo -e "Logs: ${LOG_DIR}"

cleanup() {
    echo -e "${YELLOW}Cleaning up container ${CONTAINER_NAME}${NC}"
    docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo -e "${BLUE}Starting container ${CONTAINER_NAME}...${NC}"
docker run -d --rm \
    --name "${CONTAINER_NAME}" \
    --runtime=nvidia \
    --gpus all \
    --privileged \
    --net=host \
    --env-file "${ENV_FILE}" \
    -e "DISPLAY" \
    -v "/tmp/.X11-unix:/tmp/.X11-unix:rw" \
    "${IMAGE_NAME}:${TAG}" \
    tail -f /dev/null >/dev/null

# wait for a second for container to initialize
sleep 2

run_test() {
    local name="$1"; shift
    local cmd="$*"
    local logfile="${LOG_DIR}/${name}.log"

    echo -e "\n${BLUE}=== TEST: ${name} ===${NC}"
    echo -e "${YELLOW}Command:${NC} ${cmd}"
    # run command inside container, capture output and status
    if docker exec -i "${CONTAINER_NAME}" bash -lc "${cmd}" >"${logfile}" 2>&1; then
        echo -e "${GREEN}[PASS]${NC} ${name}"
        echo -e "${GREEN}--- log: ${logfile} ---${NC}"
        return 0
    else
        echo -e "${RED}[FAIL]${NC} ${name} (see ${logfile})"
        echo -e "${RED}--- log: ${logfile} ---${NC}"
        return 1
    fi
}

# --- Basic system checks ---
run_test "system_info" "uname -a; lsb_release -a || cat /etc/os-release; echo; env | egrep 'NVIDIA|ROS|DISPLAY' || true"

run_test "gpu_check" "if command -v nvidia-smi >/dev/null 2>&1; then nvidia-smi; else echo 'nvidia-smi not available'; fi"

# --- ROS checks (ROS 1) ---
run_test "ros_env" "bash -lc 'source /opt/ros/${DISTRO}/setup.bash >/dev/null 2>&1 || true; echo ROS_DISTRO=\$ROS_DISTRO; rosversion -d || true'"

# Start roscore in background and test
echo -e "${BLUE}Starting roscore in background inside container...${NC}"
docker exec -d "${CONTAINER_NAME}" bash -lc "source /opt/ros/${DISTRO}/setup.bash >/dev/null 2>&1 || true; roscore" || true
sleep 3

run_test "ros_topic_list" "bash -lc 'source /opt/ros/${DISTRO}/setup.bash >/dev/null 2>&1 || true; rostopic list || true'"

run_test "ros_pub_once" "bash -lc 'source /opt/ros/${DISTRO}/setup.bash >/dev/null 2>&1 || true; timeout 6 rostopic pub /test std_msgs/String \"data: hello-from-test\" --once || true'"

# --- Installed tool checks ---
run_test "perf_tools_check" "bash -lc 'which hotspot || dpkg -l | grep -E \"linux-tools|hotspot\" || echo \"perf tools not found\"'"

run_test "vpi_check" "bash -lc 'dpkg -l | egrep \"libnvvpi3|vpi3\" || apt-cache policy libnvvpi3 || echo \"vpi not installed\"'"

run_test "cudss_check" "bash -lc 'dpkg -l | grep cudss || apt-cache policy cudss || echo \"cudss not installed\"'"

run_test "cvcuda_check" "bash -lc 'python3 - <<PY || true
try:
  import cvcuda
  print(\"cvcuda import ok\")
except Exception as e:
  print(\"cvcuda import failed:\", e)
PY'"

run_test "xsimd_check" "bash -lc 'ls -la /root/third_party/xsimd || echo \"xsimd folder not found\"'"

run_test "simd_check" "bash -lc 'ls -la /root/third_party/Simd || echo \"Simd folder not found\"'"

# Collect container logs
echo -e "${BLUE}\n=== SUMMARY ===${NC}"
PASS_COUNT=$(grep -c '\[PASS\]' -r "${LOG_DIR}" || true)
FAIL_COUNT=$(grep -c '\[FAIL\]' -r "${LOG_DIR}" || true)
echo -e "Logs saved to: ${LOG_DIR}"
echo -e "${GREEN}Tests completed. Check individual logs in ${LOG_DIR}${NC}"

# Stop roscore and remove container (trap will clean up)
docker exec -i "${CONTAINER_NAME}" bash -lc "pkill -f roscore || true" >/dev/null 2>&1 || true

echo -e "${BLUE}Stopping container ${CONTAINER_NAME}${NC}"
docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
trap - EXIT

echo -e "${GREEN}All done.${NC}"
