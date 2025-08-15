#!/bin/bash
set -euo pipefail

THIRD_PARTY_DIR="/root/third_party"
mkdir -p "$THIRD_PARTY_DIR"
cd "$THIRD_PARTY_DIR"

echo "--- Installing xsimd library ---"
if [ ! -d "xsimd" ]; then
    git clone https://github.com/xtensor-stack/xsimd.git
fi

cd xsimd
mkdir -p build
cd build

cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..
make -j"$(nproc)"
make install

echo "--- xsimd installation complete ---"