#!/usr/bin/env bash
set -euo pipefail
source /opt/ros/noetic/setup.bash || true
rosversion -d
roscore --version || true
