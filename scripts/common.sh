#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MATRIX_FILE="${ROOT_DIR}/config/matrix.yaml"
DOCKERHUB_CFG="${ROOT_DIR}/config/dockerhub.yaml"

yq_read() { yq "$@"; }

namespace() { yq_read '.namespace' "${MATRIX_FILE}"; }

dh_namespace() { yq_read '.namespace' "${DOCKERHUB_CFG}"; }
dh_repo() { yq_read '.repo' "${DOCKERHUB_CFG}"; }

image_list() { yq_read '.images[]' "${MATRIX_FILE}"; }

compute_base_tag() {
  local distro="$1" variant="$2"
  cat "${ROOT_DIR}/distros/${distro}/${variant}/base.tag"
}

compute_ros_meta() {
  local distro="$1" variant="$2"
  local f="${ROOT_DIR}/distros/${distro}/${variant}/ros-meta.tag"
  if [[ -f "$f" ]]; then cat "$f"; fi
}

apt_extras_path() {
  local distro="$1" variant="$2"
  echo "${ROOT_DIR}/distros/${distro}/${variant}/apt.txt"
}

pip_extras_path() {
  local distro="$1" variant="$2"
  echo "${ROOT_DIR}/distros/${distro}/${variant}/requirements.txt"
}

ensure_tools() {
  command -v yq >/dev/null || { echo "Please install yq"; exit 1; }
  command -v docker >/dev/null || { echo "Please install Docker"; exit 1; }
}

tag_for() {
  local tag="$1"
  local ns; ns="$(dh_namespace)"
  local repo; repo="$(dh_repo)"
  echo "${ns}/${repo}:${tag}"
}

render_dockerfile() {
  local distro="$1" variant="$2"
  "${ROOT_DIR}/scripts/render_dockerfile.sh" --distro "${distro}" --variant "${variant}"
}
