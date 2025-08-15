#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

usage() {
  echo "Usage: $0 [--distro <name>] [--variant cpu|gpu]"
}

DISTRO=""
VARIANT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --distro) DISTRO="$2"; shift 2 ;;
    --variant) VARIANT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) shift ;;
  esac
done

smoke_cpu() {
  local image="$1" distro="$2"
  # X11 host setup expected: xhost +local:root; share /tmp/.X11-unix and DISPLAY
  docker run --rm \
    -e DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
    "${image}" bash -lc "
set -e
if [[ '${distro}' == 'noetic' ]]; then
  source /opt/ros/noetic/setup.bash || true
  roscore --version || true
else
  source /opt/ros/${distro}/setup.bash || true
  ros2 pkg list | head -n 1 || true
fi
glxinfo -B || true
xeyes -version || true
"
}

smoke_gpu() {
  local image="$1" distro="$2"
  docker run --rm --gpus all \
    -e DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
    "${image}" bash -lc "
set -e
nvidia-smi
if [[ '${distro}' == 'noetic' ]]; then
  source /opt/ros/noetic/setup.bash || true
else
  source /opt/ros/${distro}/setup.bash || true
fi
glxinfo -B || true
"
}

run_one() {
  local distro="$1" variant="$2" tag="$3"
  local image; image="$(tag_for "$tag")"
  if [[ "$variant" == "cpu" ]]; then
    smoke_cpu "$image" "$distro"
  else
    smoke_gpu "$image" "$distro"
  fi
}

if [[ -n "$DISTRO" && -n "$VARIANT" ]]; then
  tag="$(yq ".images[] | select(.distro==\"$DISTRO\" and .variant==\"$VARIANT\") | .tag" "${ROOT_DIR}/config/matrix.yaml")"
  [[ -n "$tag" ]] || { echo "No matrix entry for ${DISTRO}/${VARIANT}"; exit 1; }
  run_one "$DISTRO" "$VARIANT" "$tag"
  exit 0
fi

yq -r '.images[] | [.distro,.variant,.tag] | @tsv' "${ROOT_DIR}/config/matrix.yaml" | \
while IFS=$'\t' read -r d v t; do
  run_one "$d" "$v" "$t"
done
