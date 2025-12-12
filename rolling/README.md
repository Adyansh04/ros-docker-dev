# ROS 2 Rolling Docker Image

Ubuntu 24.04 LTS with ROS 2 Rolling Ridley (development), CUDA 13.0, and GPU acceleration support.

## Overview

| Component | Version |
|-----------|---------|
| Base OS | Ubuntu 24.04 (Noble) |
| ROS | ROS 2 Rolling Ridley |
| CUDA | 13.0 with cuDNN |
| Python | 3.12 |

## ⚠️ Rolling Distribution Notice

**Rolling is a development distribution** that continuously receives updates. It may contain:
- Breaking API changes
- Unstable features
- Package incompatibilities

Use Rolling for:
- Testing upcoming features
- Contributing to ROS 2 development
- Early adoption of new capabilities

For production, use stable distributions like Humble, Jazzy, or Kilted.

## Quick Start

```bash
# Build the image
cd /path/to/ros-docker-dev
./build.sh rolling

# Run the container
xhost +local:docker  # Allow X11 access
./run.sh rolling
```

## Directory Structure

```
rolling/
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

**Note**: Ubuntu 24.04 uses PEP 668 externally managed environments. The Dockerfile uses `--break-system-packages` flag.

### Adding ROS Packages

Edit `ros-pkgs.txt`:

```text
# ros-pkgs.txt
ros-rolling-navigation2
ros-rolling-slam-toolbox
ros-rolling-your-package
```

**Note**: Not all packages may be available for Rolling. Check [ROS Index](https://index.ros.org/) for availability.

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
ROS_DISTRO=rolling
ROS_DOMAIN_ID=0
```

## Build Arguments

```bash
docker build \
  --build-arg ROS_DISTRO=rolling \
  --build-arg ROS_DOMAIN_ID=1 \
  -t ros-dev:rolling .
```

## Pre-installed ROS Packages

- `ros-rolling-desktop` - Desktop installation (not full due to package availability)
- `ros-rolling-navigation2` - Navigation stack
- `ros-rolling-slam-toolbox` - SLAM
- `ros-rolling-ros2-control` - Control framework
- `ros-rolling-xacro` - URDF macros

## Differences from Stable Distributions

1. **Package Availability**: Some packages may not be built for Rolling yet
2. **API Stability**: APIs may change without deprecation warnings
3. **Documentation**: Documentation may lag behind actual implementation
4. **Testing**: Less tested than stable distributions

## Keeping Up to Date

Rolling images should be rebuilt frequently to get latest updates:

```bash
# Rebuild with no cache to get latest packages
docker build --no-cache -t ros-dev:rolling .
```

## Testing

```bash
./test.sh rolling
```

Logs are saved to `./rolling_test_logs/`.

## Troubleshooting

### Package Not Found

If a ROS package fails to install:

1. Check if it's available for Rolling: `apt-cache search ros-rolling-<package>`
2. The package may not be ported yet - check ROS Discourse or GitHub issues
3. Consider building from source as a workaround
