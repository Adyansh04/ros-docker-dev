#!/bin/bash
set -euo pipefail

THIRD_PARTY_DIR="/root/third_party"
mkdir -p "$THIRD_PARTY_DIR"
cd "$THIRD_PARTY_DIR"

echo "--- Installing Simd library ---"
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

make -j 20
make install

echo "--- Simd installation complete ---"