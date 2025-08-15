#!/usr/bin/env bash
set -euo pipefail
source /opt/ros/${ROS_DISTRO}/setup.bash || true
ros2 --help >/dev/null
ros2 pkg list | head -n 5
