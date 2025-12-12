# ROS Docker Dev (multi-distro)

A comprehensive Docker-based development environment for ROS (Robot Operating System) supporting multiple distributions with NVIDIA CUDA GPU acceleration.

## Features

- **Multi-distro support**: ROS 1 Noetic and ROS 2 (Humble, Jazzy, Kilted, Rolling)
- **GPU acceleration**: CUDA and cuDNN pre-configured for NVIDIA GPUs
- **Modular design**: Easy addition of packages via text files
- **Third-party libraries**: CV-CUDA, cuDSS, VPI, Simd, xsimd pre-installed
- **CI/CD ready**: GitHub Actions workflow for Docker Hub publishing
- **Test harness**: Automated validation scripts for each distro

## Supported Distributions

| Distribution | ROS Version | Ubuntu | CUDA | Status |
|-------------|-------------|--------|------|--------|
| [humble](humble/) | ROS 2 Humble Hawksbill | 22.04 | 13.0 | ✅ LTS (2027) |
| [jazzy](jazzy/) | ROS 2 Jazzy Jalisco | 24.04 | 13.0 | ✅ LTS (2029) |
| [kilted](kilted/) | ROS 2 Kilted Kaiju | 24.04 | 13.0 | ✅ Stable |
| [noetic](noetic/) | ROS 1 Noetic Ninjemys | 20.04 | 12.6 | ✅ LTS (2025) |
| [rolling](rolling/) | ROS 2 Rolling Ridley | 24.04 | 13.0 | ⚠️ Development |

## Quick Start

### Prerequisites

- Docker with NVIDIA Container Toolkit
- NVIDIA GPU with compatible drivers
- X11 display server (for GUI applications)

### Build and Run

```bash
# Clone the repository
git clone https://github.com/Adyansh04/ros-docker-dev.git
cd ros-docker-dev

# Build an image (example: humble)
./build.sh humble

# Allow X11 access for GUI apps
xhost +local:docker

# Run the container
./run.sh humble
```

### Available Commands

| Command | Description |
|---------|-------------|
| `./build.sh <distro>` | Build Docker image for specified distro |
| `./run.sh <distro>` | Run container with GPU and X11 support |
| `./<distro>/test.sh` | Run automated tests for the image |

## Repository Structure

```
ros-docker-dev/
├── build.sh                    # Build helper script
├── run.sh                      # Run helper script
├── README.md                   # This file
├── .github/
│   └── workflows/
│       └── publish-docker.yml  # CI/CD workflow
├── humble/                     # ROS 2 Humble configuration
│   ├── Dockerfile
│   ├── README.md               # Distro-specific documentation
│   ├── apt-packages.txt        # APT packages
│   ├── pip-packages.txt        # Python packages
│   ├── ros-pkgs.txt            # ROS packages
│   ├── env.list                # Environment variables
│   ├── test.sh                 # Test script
│   ├── third_party/            # Third-party library installers
│   └── tools/                  # Development tool installers
├── jazzy/                      # ROS 2 Jazzy configuration
├── kilted/                     # ROS 2 Kilted configuration
├── noetic/                     # ROS 1 Noetic configuration
└── rolling/                    # ROS 2 Rolling configuration
```

Each distro folder has its own README with specific documentation.

## Customization

### Adding Packages

Each distro uses text files for package management:

| File | Purpose | Example |
|------|---------|---------|
| `apt-packages.txt` | System packages | `git`, `vim`, `htop` |
| `pip-packages.txt` | Python packages | `numpy`, `scipy` |
| `ros-pkgs.txt` | ROS packages | `ros-humble-navigation2` |

Simply add package names (one per line) and rebuild.

### Adding Third-Party Libraries

Create a shell script in `<distro>/third_party/`:

```bash
#!/usr/bin/env bash
set -euo pipefail

THIRD_PARTY_DIR="/root/third_party"
mkdir -p "$THIRD_PARTY_DIR"
cd "$THIRD_PARTY_DIR"

# Your installation commands here
git clone https://github.com/example/library.git
cd library && mkdir build && cd build
cmake .. && make -j"$(nproc)" && make install
```

Scripts are automatically executed during Docker build.

### Adding Development Tools

Create a shell script in `<distro>/tools/`:

```bash
#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y your-tool
```

### Environment Variables

Edit `<distro>/env.list` to set container environment:

```text
NVIDIA_VISIBLE_DEVICES=all
NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics,video,display
QT_X11_NO_MITSHM=1
ROS_DISTRO=humble
ROS_DOMAIN_ID=0
MY_CUSTOM_VAR=value
```

## Pre-installed Third-Party Libraries

| Library | Description | Documentation |
|---------|-------------|---------------|
| CV-CUDA | GPU-accelerated computer vision | [cv_cuda.sh](humble/third_party/cv_cuda.sh) |
| cuDSS | CUDA Direct Sparse Solvers | [cudss.sh](humble/third_party/cudss.sh) |
| VPI | NVIDIA Vision Programming Interface | [vpi_nv.sh](humble/third_party/vpi_nv.sh) |
| Simd | High-performance image processing | [simd_cv.sh](humble/third_party/simd_cv.sh) |
| xsimd | SIMD wrapper library | [xsimd.sh](humble/third_party/xsimd.sh) |

Libraries are installed to `/root/third_party` and environment variables are set via `/etc/profile.d/`.

## GitHub Actions Workflow

### Features

- **Dropdown distro selection**: Choose individual distros or "all"
- **Matrix builds**: Parallel building when "all" is selected
- **Build caching**: GitHub Actions cache for faster builds
- **Custom tagging**: Optional tag suffix for versioning

### Setup

1. Create Docker Hub access token (Docker Hub → Account → Security → New Access Token)

2. Add GitHub repository secrets:
   - `DOCKERHUB_USERNAME`: Your Docker Hub username
   - `DOCKERHUB_TOKEN`: Docker Hub access token

3. Trigger workflow via GitHub UI or CLI:

```bash
# Build single distro
gh workflow run publish-docker.yml -f distro=humble

# Build all distros in parallel
gh workflow run publish-docker.yml -f distro=all

# Build with custom tag suffix
gh workflow run publish-docker.yml -f distro=humble -f tag_suffix=-v1.0
```

### Resulting Tags

| Input | Resulting Tags |
|-------|----------------|
| `distro=humble` | `username/ros-dev:humble` |
| `distro=humble, tag_suffix=-dev` | `username/ros-dev:humble`, `username/ros-dev:humble-dev` |
| `distro=all` | Tags for all 5 distros |

## Build Arguments

Override defaults at build time:

```bash
docker build \
  --build-arg ROS_DISTRO=humble \
  --build-arg ROS_DOMAIN_ID=1 \
  --build-arg NVIDIA_VISIBLE_DEVICES=0 \
  -t ros-dev:humble ./humble
```

| Argument | Default | Description |
|----------|---------|-------------|
| `ROS_DISTRO` | varies | ROS distribution name |
| `ROS_DOMAIN_ID` | 0 | ROS domain ID for multi-robot |
| `NVIDIA_VISIBLE_DEVICES` | all | GPU visibility |
| `NVIDIA_DRIVER_CAPABILITIES` | compute,utility,graphics,video,display | Driver capabilities |
| `QT_X11_NO_MITSHM` | 1 | Qt X11 setting |

## Testing

Each distro includes a test script that validates:

- System information and GPU access
- ROS environment configuration
- ROS communication (topics, nodes)
- Third-party library installation
- Development tools availability

```bash
# Run tests for a specific distro
chmod +x humble/test.sh
./humble/test.sh

# Logs are saved to ./<distro>_test_logs/
```

## Troubleshooting

### GPU Not Detected

```bash
# Verify NVIDIA Container Toolkit is installed
nvidia-container-cli info

# Check Docker runtime configuration
docker info | grep -i runtime
```

### X11 Display Issues

```bash
# Allow Docker to access X11
xhost +local:docker

# Verify DISPLAY variable is set
echo $DISPLAY
```

### Build Failures

1. Check Docker has sufficient disk space
2. Ensure network access to package repositories
3. Review build logs for specific package errors
4. For Rolling, some packages may not be available

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `./build.sh <distro>` and `./test.sh <distro>`
5. Submit a pull request

## License

This project is open source. See individual package licenses for third-party components.

## TODO

- Add multi-arch build support for ARM64
- Add GitHub Container Registry as alternative
- Add development container (devcontainer) configuration
