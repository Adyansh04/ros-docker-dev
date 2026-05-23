#!/usr/bin/env bash
set -euo pipefail

# Installs kernel-specific linux-tools and hotspot. Assumes running as root in Docker build.
APT_CMD="apt-get"

export DEBIAN_FRONTEND=noninteractive

echo "--- perf_tools: update apt lists ---"
$APT_CMD update

echo "--- perf_tools: install kernel-specific linux-tools (or generic) ---"
KERNEL_PKG="linux-tools-$(uname -r)"
if ! $APT_CMD install -y --no-install-recommends "$KERNEL_PKG"; then
    echo "Failed to install ${KERNEL_PKG}, trying linux-tools-generic"
    $APT_CMD install -y --no-install-recommends linux-tools-generic
fi

echo "--- perf_tools: install hotspot ---"
$APT_CMD install -y --no-install-recommends hotspot

echo "perf_tools installation complete"