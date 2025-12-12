# Contributing to ROS Docker Dev

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## Development Setup

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/ros-docker-dev.git
   cd ros-docker-dev
   ```

2. **Ensure you have Docker with NVIDIA support**
   ```bash
   docker --version
   nvidia-container-cli info
   ```

## Adding a New ROS Distribution

1. **Create the distro directory structure**
   ```bash
   mkdir -p new-distro/{third_party,tools}
   ```

2. **Create required files**
   - `Dockerfile` - Use an existing distro as template
   - `apt-packages.txt` - System packages
   - `pip-packages.txt` - Python packages
   - `ros-pkgs.txt` - ROS packages
   - `env.list` - Environment variables
   - `test.sh` - Test script
   - `README.md` - Distro-specific documentation

3. **Copy third-party installers**
   ```bash
   cp humble/third_party/*.sh new-distro/third_party/
   cp humble/tools/*.sh new-distro/tools/
   ```

4. **Update the main files**
   - Add distro to `.github/workflows/publish-docker.yml`
   - Update `README.md` with new distro information

## Adding a New Third-Party Library

1. **Create an installer script**
   ```bash
   cat > humble/third_party/your-library.sh << 'EOF'
   #!/usr/bin/env bash
   set -euo pipefail

   THIRD_PARTY_DIR="/root/third_party"
   mkdir -p "$THIRD_PARTY_DIR"
   cd "$THIRD_PARTY_DIR"

   # Installation commands
   git clone https://github.com/example/library.git
   cd library && mkdir build && cd build
   cmake .. && make -j"$(nproc)" && make install
   EOF
   ```

2. **Make it executable**
   ```bash
   chmod +x humble/third_party/your-library.sh
   ```

3. **Copy to other distros** (if applicable)
   ```bash
   for distro in jazzy kilted noetic rolling; do
     cp humble/third_party/your-library.sh $distro/third_party/
   done
   ```

4. **Test the build**
   ```bash
   ./build.sh humble
   ```

## Coding Standards

### Shell Scripts

- Use `#!/usr/bin/env bash` shebang
- Always use `set -euo pipefail`
- Use `"$(nproc)"` for parallel builds (not hardcoded values)
- Add descriptive echo statements for progress
- Handle errors gracefully

### Dockerfiles

- Use clear section comments
- Minimize layers where possible
- Clean up in the same layer when installing packages
- Use `--no-install-recommends` for apt
- Clear `/tmp` at the end

### Documentation

- Update README.md files when adding features
- Include usage examples
- Document environment variables and build arguments
- Keep tables aligned and formatted

## Testing

Before submitting a PR:

1. **Build the image**
   ```bash
   ./build.sh <distro>
   ```

2. **Run the test script**
   ```bash
   ./<distro>/test.sh
   ```

3. **Verify GPU access**
   ```bash
   docker run --rm --gpus all ros-dev:<distro> nvidia-smi
   ```

4. **Test ROS functionality**
   ```bash
   docker run --rm ros-dev:<distro> bash -c "source /opt/ros/<distro>/setup.bash && ros2 --help"
   ```

## Pull Request Process

1. Create a feature branch from `main`
2. Make your changes following the guidelines above
3. Test thoroughly
4. Update documentation as needed
5. Submit a PR with a clear description

## Questions?

Open an issue for questions or suggestions.
