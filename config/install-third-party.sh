#!/bin/bash
# Third-party library installation template

set -e

echo "Installing third-party libraries..."

# Create a directory for all third-party libraries
THIRD_PARTY_DIR="/workspace/third_party"
mkdir -p "$THIRD_PARTY_DIR"
cd "$THIRD_PARTY_DIR"

# -------------------------------
# Install Simd library
# -------------------------------
if [ ! -d "Simd" ]; then
    git clone https://github.com/ermig1979/Simd.git
fi

cd Simd
mkdir -p build
cd build
cmake ../prj/cmake \
    -DSIMD_TOOLCHAIN="" \
    -DSIMD_TARGET="" \
    -DSIMD_AVX512=ON \
    -DSIMD_AVX512VNNI=ON \
    -DSIMD_AMXBF16=ON \
    -DSIMD_TEST=ON \
    -DSIMD_INFO=ON \
    -DSIMD_PERF=OFF \
    -DSIMD_SHARED=ON \
    -DSIMD_GET_VERSION=ON \
    -DSIMD_SYNET=ON \
    -DSIMD_INT8_DEBUG=OFF \
    -DSIMD_HIDE=OFF \
    -DSIMD_RUNTIME=ON \
    -DSIMD_OPENCV=ON \
    -DSIMD_INSTALL=ON \
    -DSIMD_UNINSTALL=ON \
    -DSIMD_PYTHON=ON
make -j$(nproc)
make install

# -------------------------------
# Install xsimd library
# -------------------------------
cd "$THIRD_PARTY_DIR"
if [ ! -d "xsimd" ]; then
    git clone https://github.com/xtensor-stack/xsimd.git
fi

cd xsimd
mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..
make -j$(nproc)
make install

echo "Third-party installation completed!"