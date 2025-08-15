#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
import sys, pkgutil
print("pip OK")
PY
