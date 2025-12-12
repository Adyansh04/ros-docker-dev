# ROS Docker Dev (multi-distro)

Lightweight helper repo to build development Docker images for multiple ROS distros
(humble, jazzy, kilted, noetic, rolling). Images include CUDA tooling, third-party installers and a test
harness.

## Repo layout
- [build.sh](build.sh) — build helper (context: ./<distro>)
- [run.sh](run.sh) — run helper (uses distro env: [<distro>/env.list](humble/env.list))
- .github/workflows/publish-docker.yml — GitHub Actions workflow for publishing images
- Distros:
  - [humble/](humble/) — ROS 2 Humble on Ubuntu 22.04 ([humble/Dockerfile](humble/Dockerfile))
  - [jazzy/](jazzy/) — ROS 2 Jazzy on Ubuntu 24.04 ([jazzy/Dockerfile](jazzy/Dockerfile))
  - [kilted/](kilted/) — ROS 2 Kilted on Ubuntu 24.04 ([kilted/Dockerfile](kilted/Dockerfile))
  - [noetic/](noetic/) — ROS 1 Noetic on Ubuntu 20.04 ([noetic/Dockerfile](noetic/Dockerfile))
  - [rolling/](rolling/) — ROS 2 Rolling on Ubuntu 24.04 ([rolling/Dockerfile](rolling/Dockerfile))
- Each distro contains:
  - Dockerfile (e.g. [humble/Dockerfile](humble/Dockerfile))
  - [env.list](humble/env.list) (controls `ROS_DISTRO` and container envs)
  - apt/pip/ros package lists: `apt-packages.txt`, `pip-packages.txt`, `ros-pkgs.txt`
  - test script: [humble/test.sh](humble/test.sh)
  - third_party installers: e.g. [humble/third_party/cv_cuda.sh](humble/third_party/cv_cuda.sh), [humble/third_party/cudss.sh](humble/third_party/cudss.sh), [humble/third_party/vpi_nv.sh](humble/third_party/vpi_nv.sh), [humble/third_party/simd_cv.sh](humble/third_party/simd_cv.sh), [humble/third_party/xsimd.sh](humble/third_party/xsimd.sh)
  - tools: e.g. [humble/tools/perf_tools.sh](humble/tools/perf_tools.sh)

## Quick start (local)

1. Build an image (example: humble):
```sh
./build.sh humble
```
Image name/tag: `ros-dev:humble` (see [build.sh](build.sh)).

2. Run the container:
```sh
# allow X11 if needed
xhost +local:docker
./run.sh humble
```
Run options mirror the script: GPU, host network/X11 and env file [humble/env.list](humble/env.list).

3. Run tests (automated checks inside a container):
```sh
chmod +x humble/test.sh
./humble/test.sh humble
```
Logs are written to `./humble_test_logs/` by default. See [humble/test.sh](humble/test.sh).

## Third-party installers
Installers live under `/<distro>/third_party/` and run during image build:
- cvcuda: [third_party/cv_cuda.sh](humble/third_party/cv_cuda.sh)
- cudss: [third_party/cudss.sh](humble/third_party/cudss.sh)
- VPI: [third_party/vpi_nv.sh](humble/third_party/vpi_nv.sh)
- Simd & xsimd: [third_party/simd_cv.sh](humble/third_party/simd_cv.sh), [third_party/xsimd.sh](humble/third_party/xsimd.sh)

These scripts install under `/root/third_party` during build and set environment snippets
(e.g. CVCUDA/CUDSS envs) so runtime shells pick them up via `/etc/profile.d`.

## Publishing images to Docker Hub (GitHub Actions)
This repo includes a manual workflow: [.github/workflows/publish-docker.yml](.github/workflows/publish-docker.yml)

### Workflow Features
- **Distro selection via dropdown**: Choose from humble, jazzy, kilted, noetic, rolling, or "all" to build multiple distros at once
- **Optional tag suffix**: Add custom suffixes like "-dev" or "-v1.0" to your image tags
- **Matrix builds**: When "all" is selected, all distros are built in parallel
- **Build caching**: Uses GitHub Actions cache for faster subsequent builds

### Steps:
1. Create Docker Hub access token (Docker Hub → Account → Security → New Access Token).
2. Add GitHub repo secrets:
   - `DOCKERHUB_USERNAME` = your Docker Hub username
   - `DOCKERHUB_TOKEN` = Docker Hub access token
3. Trigger the workflow (UI) — Actions → "Build & Push Docker Images (Docker Hub)" → Run workflow.
   - Select distro from dropdown (humble, jazzy, kilted, noetic, rolling, or all)
   - Optionally add a tag suffix (e.g., "-dev", "-v1.0")
4. Or use GitHub CLI:
```sh
# Build single distro
gh workflow run publish-docker.yml --repo <owner>/<repo> -f distro=humble

# Build all distros
gh workflow run publish-docker.yml --repo <owner>/<repo> -f distro=all

# Build with custom tag suffix
gh workflow run publish-docker.yml --repo <owner>/<repo> -f distro=humble -f tag_suffix=-dev
```

Notes on triggers
- The included workflow is `workflow_dispatch` (manual). You can change triggers to:
  - `push` on `main` (auto-publish on commits),
  - `push` on tags (`refs/tags/*`) to publish based on git tags,
  - `release` events or `schedule` (cron).
- Choose triggers according to your CI/CD policy (avoid publishing from PR builds unless intended).

## Environment and defaults
- The docker build step passes `ROS_DISTRO` via build-args from [build.sh](build.sh).
- Container env defaults live in each distro `env.list` (e.g. [`ROS_DISTRO` in humble/env.list](humble/env.list)).

## TODO
- Add multi-arch build support if you require ARM images.
