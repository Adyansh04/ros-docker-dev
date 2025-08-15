# ...existing code...
#!/usr/bin/env bash
set -euo pipefail

# Auto-detect architecture, CUDA major version and Python version, then
# download and install matching cvcuda .deb packages (lib, dev, python).
#
# Usage:
#  - Optionally override CVCUDA_VERSION: CVCUDA_VERSION=0.15.0 ./cv_cuda.sh
#  - Optionally override CVCUDA_GITHUB_TAG (example: v0.15.0-beta)
#  - Script will download from the single GitHub release URL and install found .deb files.

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
CVCUDA_VERSION="${CVCUDA_VERSION:-0.15.0}"   # default can be overridden by env
CVCUDA_GITHUB_TAG="${CVCUDA_GITHUB_TAG:-v0.15.0-beta}"  # default tag (overrideable)

echo "--- cv_cuda: using CVCUDA_VERSION=${CVCUDA_VERSION} and GITHUB_TAG=${CVCUDA_GITHUB_TAG} ---"

# Detect architecture
ARCH_RAW="$(uname -m)"
case "$ARCH_RAW" in
  x86_64|amd64) ARCH="x86_64" ;;
  aarch64|arm64) ARCH="aarch64" ;;
  *)
    echo "Unsupported arch: ${ARCH_RAW}" >&2
    exit 1
    ;;
esac
echo "Detected ARCH=${ARCH}"

# Detect CUDA major version (try nvcc, nvidia-smi, /usr/local/cuda/version.txt)
CUDA_MAJOR=""
if command -v nvcc >/dev/null 2>&1; then
    CUDA_MAJOR="$(nvcc --version | sed -n 's/.*release \([0-9]\+\).*/\1/p' | head -n1 || true)"
fi
if [ -z "$CUDA_MAJOR" ] && command -v nvidia-smi >/dev/null 2>&1; then
    CUDA_MAJOR="$(nvidia-smi 2>/dev/null | sed -n 's/.*CUDA Version: \([0-9]\+\).*/\1/p' | head -n1 || true)"
fi
if [ -z "$CUDA_MAJOR" ] && [ -f /usr/local/cuda/version.txt ]; then
    CUDA_MAJOR="$(sed -n 's/CUDA Version \([0-9]\+\).*/\1/p' /usr/local/cuda/version.txt || true)"
fi
# Fallback to 12 if detection failed
CUDA_MAJOR="${CUDA_MAJOR:-12}"
echo "Detected CUDA_MAJOR=${CUDA_MAJOR}"

# Build CUDA token for filenames: e.g. cuda11, cuda12
CU_VER="cuda${CUDA_MAJOR}"

# Detect best Python version available for bindings (prefer highest minor)
PY_VER=""
for v in 3.12 3.11 3.10 3.9; do
    if command -v "python${v}" >/dev/null 2>&1; then
        PY_VER="${v}"
        break
    fi
done
# Fallback to generic python3 if no specific minor found
if [ -z "$PY_VER" ]; then
    if command -v python3 >/dev/null 2>&1; then
        PY_VER="$(python3 -c 'import sys; print("{}.{}".format(sys.version_info.major,sys.version_info.minor))')"
    fi
fi
if [ -z "$PY_VER" ]; then
    echo "No python3 found; python bindings will be skipped"
else
    echo "Detected Python version: ${PY_VER}"
fi

# Construct filenames (single-location approach)
LIB_DEB="cvcuda-lib-${CVCUDA_VERSION}-${CU_VER}-${ARCH}-linux.deb"
DEV_DEB="cvcuda-dev-${CVCUDA_VERSION}-${CU_VER}-${ARCH}-linux.deb"
PY_DEB=""
if [ -n "$PY_VER" ]; then
    # filenames use python<major.minor> prefix, e.g. python3.10
    PY_DEB="cvcuda-python${PY_VER}-${CVCUDA_VERSION}-${CU_VER}-${ARCH}-linux.deb"
fi

# Single GitHub release base URL (use provided reference pattern)
BASE_URL="https://github.com/CVCUDA/CV-CUDA/releases/download/${CVCUDA_GITHUB_TAG}"

download_and_install_single() {
    local fname="$1"
    url="${BASE_URL}/${fname}"
    echo "--- Trying download: ${url} ---"
    if wget -q --show-progress "${url}" -O "${fname}"; then
        echo "Downloaded ${fname}"
        ${SUDO} apt-get update || true
        echo "Installing ${fname} via apt"
        ${SUDO} apt install -y "./${fname}"
        return 0
    else
        echo "File not found at ${url}, skipping ${fname}"
        rm -f "${fname}" || true
        return 1
    fi
}

# Install lib and dev packages (required)
echo "--- cv_cuda: attempting to install ${LIB_DEB} and ${DEV_DEB} from ${BASE_URL} ---"
download_and_install_single "${LIB_DEB}" || true
download_and_install_single "${DEV_DEB}" || true

# Install python bindings if a candidate was constructed
if [ -n "$PY_DEB" ]; then
    echo "--- cv_cuda: attempting to install python binding ${PY_DEB} from ${BASE_URL} ---"
    download_and_install_single "${PY_DEB}" || true
fi

# Provide environment variables for build/runtime if installed under /usr/local
CVCUDA_DIR_DETECTED="$(ls -d /usr/local/cvcuda-* 2>/dev/null | head -n1 || true)"
if [ -z "$CVCUDA_DIR_DETECTED" ]; then
    CVCUDA_DIR_DETECTED="/usr/local/cvcuda-${CVCUDA_VERSION}"
fi

echo "Detected/assumed CVCUDA_DIR=${CVCUDA_DIR_DETECTED}"

CVCUDA_ENV_FILE="/etc/profile.d/cvcuda.sh"
${SUDO} /bin/sh -c "cat > ${CVCUDA_ENV_FILE}" <<EOF
# cvcuda environment (auto-generated)
export CVCUDA_DIR='${CVCUDA_DIR_DETECTED}'
export CMAKE_PREFIX_PATH=\"\$CVCUDA_DIR:\$CMAKE_PREFIX_PATH\"
export LD_LIBRARY_PATH=\"\$CVCUDA_DIR/lib:\$LD_LIBRARY_PATH\"
EOF
${SUDO} chmod +x "${CVCUDA_ENV_FILE}"

${SUDO} grep -qxF "CVCUDA_DIR=${CVCUDA_DIR_DETECTED}" /etc/environment || ${SUDO} bash -c "echo 'CVCUDA_DIR=${CVCUDA_DIR_DETECTED}' >> /etc/environment"
${SUDO} grep -qxF "LD_LIBRARY_PATH=${CVCUDA_DIR_DETECTED}/lib" /etc/environment || ${SUDO} bash -c "echo 'LD_LIBRARY_PATH=${CVCUDA_DIR_DETECTED}/lib' >> /etc/environment"

echo "cvcuda install script finished. Verify with: python${PY_VER} -c 'import cvcuda' (if python bindings installed)."
echo "If you want to use the exact URL from your reference, set: CVCUDA_GITHUB_TAG='v0.15.0-beta'"
# ...existing code...