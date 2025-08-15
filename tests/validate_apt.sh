#!/usr/bin/env bash
set -euo pipefail
while read -r pkg; do
  [[ -z "$pkg" ]] && continue
  apt-cache show "$pkg" >/dev/null 2>&1 || { echo "Missing apt package: $pkg"; exit 1; }
done < "${1:-/dev/null}"
