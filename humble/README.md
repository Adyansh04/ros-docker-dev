# ROS 2 Humble Docker Image

Ubuntu 22.04 LTS with ROS 2 Humble Hawksbill, CUDA 13.0, and GPU acceleration support.

## Overview

| Component | Version |
|-----------|---------|
| Base OS | Ubuntu 22.04 (Jammy) |
| ROS | ROS 2 Humble Hawksbill |
| CUDA | 13.0 with cuDNN |
| Python | 3.10 |

## Quick Start

```bash
# Build the image
cd /path/to/ros-docker-dev
./build.sh humble

# Run the container
xhost +local:docker  # Allow X11 access
./run.sh humble
```

## Directory Structure

```
humble/
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

### Adding ROS Packages

Edit `ros-pkgs.txt` to add ROS packages:

```text
# ros-pkgs.txt
ros-humble-navigation2
ros-humble-slam-toolbox
ros-humble-your-package
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
# Example: git clone, cmake, make install

echo "--- Installation complete ---"
```

The script will be automatically executed during Docker build.

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

Edit `env.list` to change container environment:

```text
# env.list
NVIDIA_VISIBLE_DEVICES=all
NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics,video,display
QT_X11_NO_MITSHM=1
ROS_DISTRO=humble
ROS_DOMAIN_ID=0
# Add your custom variables here
MY_CUSTOM_VAR=value
```

### Modifying the Dockerfile

The Dockerfile is organized into sections:

1. **Section 1**: Locale setup
2. **Section 2**: ROS 2 sources setup
3. **Section 3**: Package installation (uses txt files)
4. **Section 4**: Custom tools and libraries (uses shell scripts)
5. **Section 5**: Environment configuration
6. **Section 6**: Cleanup

To add custom build steps, modify the appropriate section or add a new one.

## Build Arguments

Override defaults at build time:

```bash
docker build \
  --build-arg ROS_DISTRO=humble \
  --build-arg ROS_DOMAIN_ID=1 \
  --build-arg NVIDIA_VISIBLE_DEVICES=0 \
  -t ros-dev:humble .
```

Available build arguments:
- `ROS_DISTRO` - ROS distribution name (default: humble)
- `ROS_DOMAIN_ID` - ROS domain ID (default: 0)
- `NVIDIA_VISIBLE_DEVICES` - GPU visibility (default: all)
- `NVIDIA_DRIVER_CAPABILITIES` - Driver capabilities (default: compute,utility,graphics,video,display)
- `QT_X11_NO_MITSHM` - Qt X11 setting (default: 1)

## Pre-installed ROS Packages

- `ros-humble-desktop-full` - Full desktop installation
- `ros-humble-ros-gz` - Gazebo integration
- `ros-humble-navigation2` - Navigation stack
- `ros-humble-slam-toolbox` - SLAM
- `ros-humble-ros2-control` - Control framework
- `ros-humble-xacro` - URDF macros

## Testing

Run the test script to validate the image:

```bash
./test.sh humble
```

This runs automated checks for:
- GPU access (nvidia-smi)
- ROS environment
- Third-party libraries
- Development tools

Logs are saved to `./humble_test_logs/`.
