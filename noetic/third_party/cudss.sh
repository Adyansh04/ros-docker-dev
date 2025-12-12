#!/usr/bin/env bash
set -euo pipefail

THIRD_PARTY_DIR="/root/third_party"
mkdir -p "$THIRD_PARTY_DIR"
cd "$THIRD_PARTY_DIR"

# Detect Ubuntu version
. /etc/os-release
VERSION_ID="${VERSION_ID:-}"

# Use sudo if available and not root
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    fi
fi

case "$VERSION_ID" in
  "20.04"|"20.4")
    echo "Installing cudss for Ubuntu 20.04"
    wget https://developer.download.nvidia.com/compute/cudss/0.6.0/local_installers/cudss-local-repo-ubuntu2004-0.6.0_0.6.0-1_amd64.deb
    ${SUDO} dpkg -i cudss-local-repo-ubuntu2004-0.6.0_0.6.0-1_amd64.deb
    ${SUDO} cp /var/cudss-local-repo-ubuntu2004-0.6.0/cudss-*-keyring.gpg /usr/share/keyrings/
    ${SUDO} apt-get update
    ${SUDO} apt-get -y install cudss
    ;;
  "22.04"|"22.4")
    echo "Installing cudss for Ubuntu 22.04"
    wget https://developer.download.nvidia.com/compute/cudss/0.6.0/local_installers/cudss-local-repo-ubuntu2204-0.6.0_0.6.0-1_amd64.deb
    ${SUDO} dpkg -i cudss-local-repo-ubuntu2204-0.6.0_0.6.0-1_amd64.deb
    ${SUDO} cp /var/cudss-local-repo-ubuntu2204-0.6.0/cudss-*-keyring.gpg /usr/share/keyrings/
    ${SUDO} apt-get update
    ${SUDO} apt-get -y install cudss
    ;;
  "24.04"|"24.4")
    echo "Installing cudss for Ubuntu 24.04"
    wget https://developer.download.nvidia.com/compute/cudss/0.6.0/local_installers/cudss-local-repo-ubuntu2404-0.6.0_0.6.0-1_amd64.deb
    ${SUDO} dpkg -i cudss-local-repo-ubuntu2404-0.6.0_0.6.0-1_amd64.deb
    ${SUDO} cp /var/cudss-local-repo-ubuntu2404-0.6.0/cudss-*-keyring.gpg /usr/share/keyrings/
    ${SUDO} apt-get update
    ${SUDO} apt-get -y install cudss
    ;;
  *)
    echo "Unsupported or unknown Ubuntu version: ${VERSION_ID}" >&2
    exit 1
    ;;
esac

# detect installed CUDSS directory and expose env vars system-wide 
# Try to detect the installed directory under /usr/local
CUDSS_DIR_DETECTED="$(ls -d /usr/local/libcudss-linux-* 2>/dev/null | head -n1 || true)"

# Fallback: use /usr if detection failed (cudss may install to system paths)
if [ -z "$CUDSS_DIR_DETECTED" ]; then
    CUDSS_DIR_DETECTED="/usr"
    echo "Warning: Could not detect cudss install directory, using fallback: ${CUDSS_DIR_DETECTED}"
fi

echo "Detected CUDSS_DIR: ${CUDSS_DIR_DETECTED}"

# Write environment exports to /etc/profile.d so interactive shells source them
CUDSS_ENV_FILE="/etc/profile.d/cudss.sh"
${SUDO} /bin/sh -c "cat > ${CUDSS_ENV_FILE}" <<EOF
# cudss environment (auto-generated)
export CUDSS_DIR='${CUDSS_DIR_DETECTED}'
export CMAKE_PREFIX_PATH=\"\$CUDSS_DIR:\$CMAKE_PREFIX_PATH\"
export LD_LIBRARY_PATH=\"\$CUDSS_DIR/lib:\$LD_LIBRARY_PATH\"
EOF

${SUDO} chmod +x "${CUDSS_ENV_FILE}"

# Also add simple variables to /etc/environment for non-interactive processes (literal values)
# Note: /etc/environment does not support variable expansion, store absolute paths.
${SUDO} grep -qxF "CUDSS_DIR=${CUDSS_DIR_DETECTED}" /etc/environment || ${SUDO} bash -c "echo 'CUDSS_DIR=${CUDSS_DIR_DETECTED}' >> /etc/environment"
${SUDO} grep -qxF "LD_LIBRARY_PATH=${CUDSS_DIR_DETECTED}/lib" /etc/environment || ${SUDO} bash -c "echo 'LD_LIBRARY_PATH=${CUDSS_DIR_DETECTED}/lib' >> /etc/environment"

echo "CUDSS environment configured: ${CUDSS_ENV_FILE} and /etc/environment updated"
