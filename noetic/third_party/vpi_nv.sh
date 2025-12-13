#!/usr/bin/env bash
set -euo pipefail

THIRD_PARTY_DIR="/root/third_party"
mkdir -p "$THIRD_PARTY_DIR"
cd "$THIRD_PARTY_DIR"

# Use sudo if available and not root
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        echo "Not running as root and sudo not available; aborting" >&2
        exit 1
    fi
fi

export DEBIAN_FRONTEND=noninteractive

# Ensure apt helpers are present
echo "--- vpi_nv: update apt and install prerequisites ---"
${SUDO} apt-get update
${SUDO} apt-get install -y --no-install-recommends gnupg software-properties-common

# Install the public key for the VPI repository (as requested)
echo "--- vpi_nv: adding VPI public key ---"
${SUDO} apt-key adv --fetch-key https://repo.download.nvidia.com/jetson/jetson-ota-public.asc

# Detect Ubuntu version
. /etc/os-release
VERSION_ID="${VERSION_ID:-}"

echo "--- vpi_nv: detected Ubuntu VERSION_ID=${VERSION_ID} ---"

case "$VERSION_ID" in
  "20.04"|"20.4")
    echo "Adding VPI repo for Ubuntu 20.04 (focal)"
    ${SUDO} add-apt-repository 'deb https://repo.download.nvidia.com/jetson/x86_64/focal r36.4 main'
    ;;
  "22.04"|"22.4")
    echo "Adding VPI repo for Ubuntu 22.04 (jammy)"
    ${SUDO} add-apt-repository 'deb https://repo.download.nvidia.com/jetson/x86_64/jammy r36.4 main'
    ;;
  *)
    echo "Unsupported or unknown Ubuntu version: ${VERSION_ID}. Attempting to use jammy repo as fallback."
    ${SUDO} add-apt-repository 'deb https://repo.download.nvidia.com/jetson/x86_64/jammy r36.4 main'
    ;;
esac

echo "--- vpi_nv: updating package lists ---"
${SUDO} apt-get update

echo "--- vpi_nv: installing VPI packages ---"
${SUDO} apt-get install -y libnvvpi3 vpi3-dev vpi3-samples

echo "--- vpi_nv: installing Python bindings (if available) ---"
case "$VERSION_ID" in
  "20.04"|"20.4")
    # Ubuntu 20.04 has Python 3.8 by default
    ${SUDO} apt-get install -y python3.8-vpi3 || true
    ;;
  "22.04"|"22.4")
    # Try to install both bindings if available
    ${SUDO} apt-get install -y python3.9-vpi3 || true
    ${SUDO} apt-get install -y python3.10-vpi3 || true
    ;;
  "24.04"|"24.4")
    # Ubuntu 24.04 has Python 3.12
    ${SUDO} apt-get install -y python3.12-vpi3 || true
    ;;
  *)
    # try generic install
    ${SUDO} apt-get install -y python3.8-vpi3 python3.9-vpi3 python3.10-vpi3 || true
    ;;
esac

echo ""
echo "vpi_nv installation finished."
echo "Note: numpy may still need to be installed for Python bindings (pip/apt/conda)."
