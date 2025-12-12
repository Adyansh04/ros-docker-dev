# ROS 2 Jazzy Docker Image

Ubuntu 24.04 LTS with ROS 2 Jazzy Jalisco, CUDA 13.0, and GPU acceleration support.

## Overview

| Component | Version |
|-----------|---------|
| Base OS | Ubuntu 24.04 (Noble) |
| ROS | ROS 2 Jazzy Jalisco |
| CUDA | 13.0 with cuDNN |
| Python | 3.12 |

## Quick Start

```bash
# Build the image
cd /path/to/ros-docker-dev
./build.sh jazzy

# Run the container
xhost +local:docker  # Allow X11 access
./run.sh jazzy
```

## Directory Structure

```
jazzy/
├── Dockerfile           # Main Docker build configuration
├── apt-packages.txt     # System packages to install via apt
├── pip-packages.txt     # Python packages to install via pip
├── ros-pkgs.txt         # ROS packages to install
├── env.list             # Environment variables for container
├── test.sh              # Container test script
├── third_party/         # Third-party library installers
│   ├── cv_cuda.sh       # CV-CUDA installation
│   ├── cudss.sh         # cuDSS installation
│   ├── simd_cv.sh       # Simd library installation
│   ├── vpi_nv.sh        # NVIDIA VPI installation
│   └── xsimd.sh         # xsimd library installation
└── tools/               # Development tool installers
    └── perf_tools.sh    # Performance tools (hotspot, linux-tools)
```

## Customization Guide

### Adding APT Packages

Edit `apt-packages.txt` to add system packages:

```text
# apt-packages.txt
# Add one package per line, comments start with #
git
vim
your-package-name
```

### Adding Python Packages

Edit `pip-packages.txt` to add Python packages:

```text
# pip-packages.txt
numpy
scipy
your-python-package
```

**Note**: Ubuntu 24.04 uses PEP 668 externally managed environments. The Dockerfile uses `--break-system-packages` flag for pip installs.

### Adding ROS Packages

Edit `ros-pkgs.txt` to add ROS packages:

```text
# ros-pkgs.txt
ros-jazzy-navigation2
ros-jazzy-slam-toolbox
ros-jazzy-your-package
```

### Adding Third-Party Libraries

Create a new `.sh` script in `third_party/`:

```bash
#!/usr/bin/env bash
set -euo pipefail

THIRD_PARTY_DIR="/root/third_party"
mkdir -p "$THIRD_PARTY_DIR"
cd "$THIRD_PARTY_DIR"

echo "--- Installing your library ---"
# Add your installation commands here

echo "--- Installation complete ---"
```

### Adding Development Tools

Create a new `.sh` script in `tools/`:

```bash
#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "--- Installing your tool ---"
apt-get update
apt-get install -y your-tool
echo "--- Installation complete ---"
```

### Modifying Environment Variables

Edit `env.list`:

```text
NVIDIA_VISIBLE_DEVICES=all
NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics,video,display
QT_X11_NO_MITSHM=1
ROS_DISTRO=jazzy
ROS_DOMAIN_ID=0
```

## Build Arguments

```bash
docker build \
  --build-arg ROS_DISTRO=jazzy \
  --build-arg ROS_DOMAIN_ID=1 \
  -t ros-dev:jazzy .
```

## Pre-installed ROS Packages

- `ros-jazzy-desktop-full` - Full desktop installation
- `ros-jazzy-ros-gz` - Gazebo integration
- `ros-jazzy-navigation2` - Navigation stack
- `ros-jazzy-slam-toolbox` - SLAM
- `ros-jazzy-ros2-control` - Control framework
- `ros-jazzy-turtle-nest` - Turtle simulation

## Ubuntu 24.04 Specific Notes

- Python packages require `--break-system-packages` flag
- Uses newer LLVM 14 toolchain
- Gazebo setup script is sourced in bashrc

## Testing

```bash
./test.sh jazzy
```

Logs are saved to `./jazzy_test_logs/`.
