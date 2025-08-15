#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

usage() {
  cat <<EOF
Usage: $0 [--distro <name>] [--variant cpu|gpu] [--no-cache]
Builds final images only (no intermediate tags).
EOF
}

DISTRO=""
VARIANT=""
NO_CACHE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --distro) DISTRO="$2"; shift 2 ;;
    --variant) VARIANT="$2"; shift 2 ;;
    --no-cache) NO_CACHE="--no-cache"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) shift ;;
  esac
done

ensure_tools

build_one() {
  local distro="$1" variant="$2" tag="$3"
  local base; base="$(compute_base_tag "$distro" "$variant")"
  local aptx; aptx="$(apt_extras_path "$distro" "$variant")"
  local pipx; pipx="$(pip_extras_path "$distro" "$variant")"

  local dockerfile; dockerfile="$(render_dockerfile "$distro" "$variant")"

  local args=(--build-arg "BASE_IMAGE=${base}"
              --build-arg "APT_EXTRAS=$(realpath "$aptx")"
              --build-arg "PIP_EXTRAS=$(realpath "$pipx")")

  # GPU may pass ROS_META if exists
  if [[ "$variant" == "gpu" ]]; then
    local ros_meta; ros_meta="$(compute_ros_meta "$distro" "$variant" || true)"
    if [[ -n "${ros_meta:-}" ]]; then
      args+=(--build-arg "ROS_META=${ros_meta}")
    fi
  fi

  local full_tag; full_tag="$(tag_for "$tag")"

  docker build ${NO_CACHE} \
    -f "${dockerfile}" \
    -t "${full_tag}" \
    "${args[@]}" \
    "${ROOT_DIR}"
}

if [[ -n "$DISTRO" && -n "$VARIANT" ]]; then
  tag="$(yq ".images[] | select(.distro==\"$DISTRO\" and .variant==\"$VARIANT\") | .tag" "${ROOT_DIR}/config/matrix.yaml")"
  [[ -n "$tag" ]] || { echo "No matrix entry for ${DISTRO}/${VARIANT}"; exit 1; }
  build_one "$DISTRO" "$VARIANT" "$tag"
  exit 0
fi

yq -r '.images[] | [.distro,.variant,.tag] | @tsv' "${ROOT_DIR}/config/matrix.yaml" | \
while IFS=$'\t' read -r d v t; do
  build_one "$d" "$v" "$t"
done
