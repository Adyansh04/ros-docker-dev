# ROS Docker Development Template

Modular, layered Docker development environment for ROS projects with official NVIDIA CUDA support.

## Architecture

**Layer Composition:**
Ubuntu Base → [NVIDIA CUDA] → ROS Layer → Dev Tools → Final Image

text

**Key Features:**
- **Modular layers** for maximum flexibility
- **Official NVIDIA CUDA images** for GPU support
- **Multi-ROS distro support** (Noetic, Humble, Jazzy, Kilted)
- **Conditional layer inclusion** based on requirements
- **VS Code devcontainer** integration

## Quick Start

Clone and configure
git clone <repo> my-ros-project && cd my-ros-project
cp .env.template .env

Build CPU-only
./scripts/build.sh --distro humble

Build with GPU support
./scripts/build.sh --distro humble --gpu --cuda 12.2

Start development
code . # VS Code with devcontainer

OR
docker-compose exec ros-dev bash

text

## Layer Details

### Layer 1: Base (Ubuntu)
- Essential system tools
- Build environment
- Foundation utilities

### Layer 2: NVIDIA (Optional)
- Official NVIDIA CUDA images
- OpenGL and GUI libraries  
- GPU acceleration support

### Layer 3: ROS
- Official ROS installation
- Gazebo simulation
- RQT tools and plugins

### Layer 4: Development
- Debugging tools (GDB, Valgrind, Perf)
- Testing frameworks
- Code quality tools

### Layer 5: Final
- Environment configuration
- Entry point setup
- Helper scripts

## Customization

**System packages:** Edit `config/apt-packages.txt`
**Python packages:** Edit `config/pip-requirements.txt`  
**Third-party libraries:** Edit `config/install-third-party.sh`

## Examples

Different ROS distros
./scripts/build.sh --distro noetic
./scripts/build.sh --distro jazzy --gpu

Force rebuild
./scripts/build.sh --rebuild

Multiple containers
docker-compose --profile noetic up -d
docker-compose --profile jazzy up -d

text

## Benefits

✅ **True modularity** - separate, composable layers  
✅ **Official NVIDIA support** - guaranteed compatibility  
✅ **No content duplication** - clean layer inheritance  
✅ **Flexible composition** - conditional layer inclusion  
✅ **Development optimized** - comprehensive tooling  
✅ **Multi-distro ready** - easy ROS version switching
Key Advantages of This Architecture
✅ True Layer Modularity: Each layer is a separate Dockerfile with single responsibility
✅ No Content Duplication: Layers inherit and extend, don't copy
✅ Conditional Composition: GPU layer only included when needed
✅ Official NVIDIA Support: Uses nvidia/cuda images directly
✅ Clean Separation: Base → GPU → ROS → Dev → Final
✅ Easy Maintenance: Modify individual layers independently
✅ Docker Best Practices: Proper multi-stage builds and layer caching

This approach gives you the modularity you requested while following Docker layer composition best practices from the documentation you referenced!