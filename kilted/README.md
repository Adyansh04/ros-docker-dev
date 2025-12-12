# ROS 2 Kilted Docker Image

Ubuntu 24.04 LTS with ROS 2 Kilted Kaiju, CUDA 13.0, and GPU acceleration support.

## Overview

| Component | Version |
|-----------|---------|
| Base OS | Ubuntu 24.04 (Noble) |
| ROS | ROS 2 Kilted Kaiju |
| CUDA | 13.0 with cuDNN |
| Python | 3.12 |

## Quick Start

```bash
# Build the image
cd /path/to/ros-docker-dev
./build.sh kilted

# Run the container
xhost +local:docker  # Allow X11 access
./run.sh kilted
```

## Directory Structure

```
kilted/
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

Edit `apt-packages.txt`:

```text
# apt-packages.txt
git
vim
your-package-name
```

### Adding Python Packages

Edit `pip-packages.txt`:

```text
# pip-packages.txt
numpy
scipy
your-python-package
```

**Note**: Ubuntu 24.04 uses PEP 668 externally managed environments. The Dockerfile uses `--break-system-packages` flag for pip installs.

### Adding ROS Packages

Edit `ros-pkgs.txt`:

```text
# ros-pkgs.txt
ros-kilted-navigation2
ros-kilted-slam-toolbox
ros-kilted-your-package
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

### Modifying Environment Variables

Edit `env.list`:

```text
NVIDIA_VISIBLE_DEVICES=all
NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics,video,display
QT_X11_NO_MITSHM=1
ROS_DISTRO=kilted
ROS_DOMAIN_ID=0
```

## Build Arguments

```bash
docker build \
  --build-arg ROS_DISTRO=kilted \
  --build-arg ROS_DOMAIN_ID=1 \
  -t ros-dev:kilted .
```

## Pre-installed ROS Packages

- `ros-kilted-desktop-full` - Full desktop installation
- `ros-kilted-ros-gz` - Gazebo integration
- `ros-kilted-navigation2` - Navigation stack
- `ros-kilted-slam-toolbox` - SLAM
- `ros-kilted-ros2-control` - Control framework
- `ros-kilted-xacro` - URDF macros

## Testing

```bash
./test.sh kilted
```

Logs are saved to `./kilted_test_logs/`.
