# ROS 2 Lyrical Docker Image

Ubuntu 26.04 LTS with ROS 2 Lyrical Luth, CUDA 13.0 (placeholder), and GPU acceleration support.

## Overview

| Component | Version |
|-----------|---------|
| Base OS | Ubuntu 26.04 (Resolute) |
| ROS | ROS 2 Lyrical Luth |
| CUDA | 13.0 with cuDNN (placeholder) |
| Python | 3.14 |

**CUDA base image note**: NVIDIA has not published an `ubuntu26.04` CUDA image yet. The Dockerfile uses a placeholder tag that you should update later, or override at build time with `BASE_IMAGE`.

## Quick Start

```bash
# Build the image
cd /path/to/ros-docker-dev
./build.sh lyrical

# Run the container
xhost +local:docker  # Allow X11 access
./run.sh lyrical
```

## Directory Structure

```
lyrical/
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

**Note**: The Dockerfile uses `--break-system-packages` for pip installs on modern Ubuntu base images.

### Adding ROS Packages

Edit `ros-pkgs.txt`:

```text
# ros-pkgs.txt
ros-lyrical-navigation2
ros-lyrical-slam-toolbox
ros-lyrical-your-package
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
ROS_DISTRO=lyrical
ROS_DOMAIN_ID=0
```

## Build Arguments

```bash
docker build \
  --build-arg ROS_DISTRO=lyrical \
  --build-arg ROS_DOMAIN_ID=1 \
  -t ros-dev:lyrical .
```

## Pre-installed ROS Packages

- `ros-lyrical-desktop-full` - Full desktop installation
- `ros-lyrical-ros-gz` - Gazebo integration
- `ros-lyrical-navigation2` - Navigation stack
- `ros-lyrical-slam-toolbox` - SLAM
- `ros-lyrical-ros2-control` - Control framework
- `ros-lyrical-xacro` - URDF macros

## Testing

```bash
./test.sh lyrical
```

Logs are saved to `./lyrical_test_logs/`.
