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

push_one() {
  local tag="$1"
  local image; image="$(tag_for "$tag")"
  docker push "$image"
}

if [[ -n "$DISTRO" && -n "$VARIANT" ]]; then
  tag="$(yq ".images[] | select(.distro==\"$DISTRO\" and .variant==\"$VARIANT\") | .tag" "${ROOT_DIR}/config/matrix.yaml")"
  [[ -n "$tag" ]] || { echo "No matrix entry for ${DISTRO}/${VARIANT}"; exit 1; }
  push_one "$tag"
  exit 0
fi

yq -r '.images[] | .tag' "${ROOT_DIR}/config/matrix.yaml" | while read -r t; do
  push_one "$t"
done
