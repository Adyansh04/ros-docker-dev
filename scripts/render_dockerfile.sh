#!/usr/bin/env bash
set -euo pipefail

# Render a Dockerfile by concatenating fragment sections in a fixed order.
# Usage: render_dockerfile.sh --distro <name> --variant cpu|gpu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

DISTRO=""
VARIANT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --distro) DISTRO="$2"; shift 2 ;;
    --variant) VARIANT="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 --distro <name> --variant cpu|gpu"
      exit 0
      ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

[[ -n "$DISTRO" && -n "$VARIANT" ]] || { echo "distro and variant required"; exit 1; }

FRAG_DIR="${ROOT_DIR}/docker/fragments"
DISTRO_DIR="${ROOT_DIR}/distros/${DISTRO}/${VARIANT}"
OUT_DIR="${ROOT_DIR}/.build/${DISTRO}/${VARIANT}"
mkdir -p "${OUT_DIR}"

BASE_TAG_FILE="${DISTRO_DIR}/base.tag"
[[ -f "${BASE_TAG_FILE}" ]] || { echo "Missing base.tag: ${BASE_TAG_FILE}"; exit 1; }
BASE_IMAGE="$(cat "${BASE_TAG_FILE}")"

ROS_META_FILE="${DISTRO_DIR}/ros-meta.tag"
ROS_META=""
if [[ -f "${ROS_META_FILE}" ]]; then
  ROS_META="$(cat "${ROS_META_FILE}")"
fi

APT_EXTRAS="${DISTRO_DIR}/apt.txt"
PIP_EXTRAS="${DISTRO_DIR}/requirements.txt"
[[ -f "${APT_EXTRAS}" ]] || : > "${APT_EXTRAS}"
[[ -f "${PIP_EXTRAS}" ]] || : > "${PIP_EXTRAS}"

DOCKERFILE="${OUT_DIR}/Dockerfile"
: > "${DOCKERFILE}"

# Header: FROM base
{
  echo "ARG BASE_IMAGE"
  echo "FROM \${BASE_IMAGE}"
  echo 'ARG DEBIAN_FRONTEND=noninteractive'
  echo 'SHELL ["/bin/bash", "-o", "pipefail", "-c"]'
  echo ""
} >> "${DOCKERFILE}"

# Common dev tools
cat "${FRAG_DIR}/devtools.Dockerfile.fragment" >> "${DOCKERFILE}"
echo "" >> "${DOCKERFILE}"

# GUI / X11 setup
cat "${FRAG_DIR}/gui-setup.Dockerfile.fragment" >> "${DOCKERFILE}"
echo "" >> "${DOCKERFILE}"

# GPU variant: add ROS apt sources prior to installing meta
if [[ "${VARIANT}" == "gpu" ]]; then
  # ROS 1 or ROS 2? Determine by distro name: noetic -> ROS 1; others -> ROS 2
  if [[ "${DISTRO}" == "noetic" ]]; then
    # Use ROS 1 fragment (still uses ros-apt-source which supports ROS1/ROS2 keys)
    cat "${FRAG_DIR}/ros1-setup.Dockerfile.fragment" >> "${DOCKERFILE}"
  else
    cat "${FRAG_DIR}/ros2-setup.Dockerfile.fragment" >> "${DOCKERFILE}"
  fi

  # Install meta if provided
  if [[ -n "${ROS_META}" ]]; then
    echo "ARG ROS_META" >> "${DOCKERFILE}"
    echo 'RUN if [ -n "$ROS_META" ]; then apt-get update && apt-get install --fix-missing -y --no-install-recommends "$ROS_META" && rm -rf /var/lib/apt/lists/*; fi' >> "${DOCKERFILE}"
    echo "" >> "${DOCKERFILE}"
  fi
fi

# Pip devtools already handled in devtools fragment (installs pip and common list)
# rosdep init/update (optional but safe)
cat "${FRAG_DIR}/rosdep-init.Dockerfile.fragment" >> "${DOCKERFILE}"
echo "" >> "${DOCKERFILE}"

# Add non-root user + bashrc conveniences (ROS sourcing, colcon, argcomplete)
cat "${FRAG_DIR}/user.Dockerfile.fragment" >> "${DOCKERFILE}"
echo "" >> "${DOCKERFILE}"

# Per-image extras from apt.txt and requirements.txt
echo "ARG APT_EXTRAS=/dev/null" >> "${DOCKERFILE}"
echo "ARG PIP_EXTRAS=/dev/null" >> "${DOCKERFILE}"
echo 'RUN if [ -s "$APT_EXTRAS" ]; then apt-get update && xargs -a "$APT_EXTRAS" apt-get install -y --no-install-recommends && rm -rf /var/lib/apt/lists/*; fi' >> "${DOCKERFILE}"
echo 'RUN if [ -s "$PIP_EXTRAS" ]; then python3 -m pip install --no-cache-dir -r "$PIP_EXTRAS"; fi' >> "${DOCKERFILE}"
echo "" >> "${DOCKERFILE}"

# Cleanups
cat "${FRAG_DIR}/clean.Dockerfile.fragment" >> "${DOCKERFILE}"
echo "" >> "${DOCKERFILE}"

# X11 and NVIDIA env hints
{
  echo "ENV NVIDIA_VISIBLE_DEVICES=all"
  echo "ENV NVIDIA_DRIVER_CAPABILITIES=all"
} >> "${DOCKERFILE}"

# Write context info for build.sh
echo "${DOCKERFILE}"
