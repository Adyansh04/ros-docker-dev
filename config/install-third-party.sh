#!/bin/bash
# Third-party library installation template

set -e

echo "Installing third-party libraries..."

# Eigen (Uncomment to install)
# echo "Installing Eigen..."
# cd /tmp
# wget https://gitlab.com/libeigen/eigen/-/archive/3.4.0/eigen-3.4.0.tar.gz
# tar -xzf eigen-3.4.0.tar.gz && cd eigen-3.4.0
# mkdir build && cd build
# cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
# make -j$(nproc) && make install
# cd / && rm -rf /tmp/eigen-3.4.0*

# Ceres Solver (Uncomment to install)
# echo "Installing Ceres Solver..."
# apt-get update && apt-get install -y libgoogle-glog-dev libgflags-dev libatlas-base-dev libeigen3-dev libsuitesparse-dev
# cd /tmp
# wget http://ceres-solver.org/ceres-solver-2.1.0.tar.gz
# tar -xzf ceres-solver-2.1.0.tar.gz && cd ceres-solver-2.1.0
# mkdir build && cd build
# cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
# make -j$(nproc) && make install
# cd / && rm -rf /tmp/ceres-solver-2.1.0*

echo "Third-party installation completed!"
