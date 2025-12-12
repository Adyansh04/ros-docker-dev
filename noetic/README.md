# ROS 1 Noetic Docker Image

Ubuntu 20.04 LTS with ROS 1 Noetic Ninjemys, CUDA 12.6, and GPU acceleration support.

## Overview

| Component | Version |
|-----------|---------|
| Base OS | Ubuntu 20.04 (Focal) |
| ROS | ROS 1 Noetic Ninjemys |
| CUDA | 12.6 with cuDNN |
| Python | 3.8 |

## Quick Start

```bash
# Build the image
cd /path/to/ros-docker-dev
./build.sh noetic

# Run the container
xhost +local:docker  # Allow X11 access
./run.sh noetic
```

## Directory Structure

```
noetic/
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

## ROS 1 vs ROS 2 Differences

This image uses **ROS 1 Noetic**, which differs from ROS 2:

| Feature | ROS 1 Noetic | ROS 2 |
|---------|--------------|-------|
| Build System | catkin | colcon |
| Package Format | catkin packages | ament packages |
| Launch Files | XML only | Python or XML |
| Core Command | `roscore` required | No roscore needed |
| Topic Commands | `rostopic`, `rosnode` | `ros2 topic`, `ros2 node` |

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

### Adding ROS Packages

Edit `ros-pkgs.txt`:

```text
# ros-pkgs.txt
ros-noetic-navigation
ros-noetic-gmapping
ros-noetic-your-package
```

**Note**: ROS 1 package names use `ros-noetic-*` format.

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
ROS_DISTRO=noetic
ROS_DOMAIN_ID=0
```

## Build Arguments

```bash
docker build \
  --build-arg ROS_DISTRO=noetic \
  -t ros-dev:noetic .
```

## Pre-installed ROS Packages

- `ros-noetic-desktop-full` - Full desktop installation
- `ros-noetic-navigation` - Navigation stack
- `ros-noetic-gmapping` - SLAM
- `ros-noetic-ros-control` - Control framework
- `ros-noetic-xacro` - URDF macros
- `ros-noetic-robot-state-publisher` - TF publisher
- `ros-noetic-joint-state-publisher` - Joint state publisher

## Pre-installed Tools

- `catkin_tools` - Modern catkin build tool
- `rosdep` - ROS dependency manager
- `rosinstall` - ROS installation tools
- `wstool` - Workspace tool

## Usage Examples

### Starting ROS 1 Core

```bash
# Inside container
roscore &
```

### Publishing a Message

```bash
rostopic pub /test std_msgs/String "data: 'hello'" --once
```

### Listing Topics

```bash
rostopic list
```

### Creating a Catkin Workspace

```bash
mkdir -p ~/catkin_ws/src
cd ~/catkin_ws
catkin init
catkin build
source devel/setup.bash
```

## Testing

```bash
./test.sh noetic
```

This runs automated checks including roscore startup and topic publishing.

Logs are saved to `./noetic_test_logs/`.
