# docker/compose/Dockerfile
# Properly structured Dockerfile using actual layer composition

ARG ROS_DISTRO=humble
ARG ENABLE_GPU=false
ARG CUDA_VERSION=12.2
ARG UBUNTU_VERSION=22.04

# ==========================================
# Stage 1: Layer Collector
# ==========================================
FROM scratch AS layer-collector
# Copy all layer Dockerfiles for reference
COPY docker/layers/01-base/Dockerfile /layers/01-base.dockerfile
COPY docker/layers/02-nvidia/Dockerfile /layers/02-nvidia.dockerfile
COPY docker/layers/03-ros/Dockerfile /layers/03-ros.dockerfile
COPY docker/layers/04-dev/Dockerfile /layers/04-dev.dockerfile
COPY docker/layers/05-final/Dockerfile /layers/05-final.dockerfile

# ==========================================
# Stage 2: Build Base Layer
# ==========================================
FROM ubuntu:${UBUNTU_VERSION} AS base-layer
LABEL layer="01-base"

# Copy base layer dockerfile for reference
COPY --from=layer-collector /layers/01-base.dockerfile /tmp/

# Implement base layer (from 01-base/Dockerfile)
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    build-essential \
    cmake \
    pkg-config \
    net-tools \
    iputils-ping \
    htop \
    tree \
    software-properties-common \
    lsb-release \
    gnupg \
    && rm -rf /var/lib/apt/lists/* && \
    mkdir -p /workspace

WORKDIR /workspace

# ==========================================
# Stage 3: Build NVIDIA Layer (Conditional)
# ==========================================
FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION} AS nvidia-layer
LABEL layer="02-nvidia"

# Copy nvidia layer dockerfile for reference
COPY --from=layer-collector /layers/02-nvidia.dockerfile /tmp/

# Copy base layer setup
COPY --from=base-layer /workspace /workspace

# Implement NVIDIA layer (from 02-nvidia/Dockerfile)
RUN apt-get update && apt-get install -y \
    curl wget git vim nano build-essential cmake pkg-config \
    net-tools iputils-ping htop tree software-properties-common \
    lsb-release gnupg \
    libgl1-mesa-dev \
    libgl1-mesa-dri \
    libglu1-mesa \
    libx11-6 \
    libxrandr2 \
    libxss1 \
    libxcursor1 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrender1 \
    libxtst6 \
    libxxf86vm1 \
    mesa-utils \
    x11-apps \
    && rm -rf /var/lib/apt/lists/*

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV DISPLAY=:0
ENV QT_X11_NO_MITSHM=1
ENV PATH="/usr/local/cuda/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"

WORKDIR /workspace

# ==========================================
# Stage 4: Base Selection Logic  
# ==========================================
FROM base-layer AS selected-base-cpu
FROM nvidia-layer AS selected-base-gpu

# ==========================================
# Stage 5: Use Official ROS Images as Base
# ==========================================
FROM osrf/ros:${ROS_DISTRO}-desktop-full AS official-ros-base
ARG ROS_DISTRO

# Copy base tools from previous layer
COPY --from=selected-base-cpu /usr/local /usr/local
COPY --from=selected-base-cpu /workspace /workspace

# Add missing tools not in official images
RUN apt-get update && apt-get install -y \
    python3-rosdep \
    python3-colcon-common-extensions \
    && rm -rf /var/lib/apt/lists/*

# ==========================================
# Stage 6: Merge with GPU layer if needed
# ==========================================
FROM selected-base-gpu AS gpu-ros-base
COPY --from=official-ros-base /opt/ros /opt/ros
COPY --from=official-ros-base /etc/ros /etc/ros
COPY --from=official-ros-base /workspace /workspace

# ==========================================
# Stage 7: Final ROS selection
# ==========================================
FROM official-ros-base AS ros-layer-cpu-final
FROM gpu-ros-base AS ros-layer-gpu-final

# ==========================================
# Stage 8: Build Development Layer
# ==========================================
FROM ros-layer-cpu-final AS ros-false
FROM ros-layer-gpu-final AS ros-true
ARG ENABLE_GPU
FROM ros-${ENABLE_GPU} AS dev-layer

LABEL layer="04-dev"

# Copy dev layer dockerfile for reference
COPY --from=layer-collector /layers/04-dev.dockerfile /tmp/

# Copy configuration files
COPY config/pip-requirements.txt /tmp/pip-requirements.txt
COPY config/apt-packages.txt /tmp/apt-packages.txt
COPY config/install-third-party.sh /tmp/install-third-party.sh

# Implement dev layer (from 04-dev/Dockerfile)
RUN apt-get update && apt-get install -y \
    gdb \
    valgrind \
    strace \
    ltrace \
    linux-tools-common \
    hotspot \
    kcachegrind \
    heaptrack \
    rr \
    electric-fence \
    cppcheck \
    clang-tidy \
    clang-format \
    ninja-build \
    ccache \
    massif-visualizer \
    wireshark-common \
    tcpdump \
    sysstat \
    iotop \
    python3-pip \
    python3-dev \
    python3-venv \
    python3-pytest \
    python3-pytest-cov \
    python3-pytest-xdist \
    python3-pytest-mock \
    python3-flake8 \
    python3-mypy \
    python3-pudb \
    python3-line-profiler \
    python3-memory-profiler \
    git-lfs \
    doxygen \
    graphviz \
    jq \
    xmlstarlet \
    netcat-openbsd \
    nmap \
    i2c-tools \
    can-utils \
    && rm -rf /var/lib/apt/lists/*

# Install custom packages
RUN pip3 install --no-cache-dir --break-system-packages -r /tmp/pip-requirements.txt && \
    apt-get update && \
    grep -v '^#' /tmp/apt-packages.txt | xargs apt-get install -y && \
    chmod +x /tmp/install-third-party.sh && /tmp/install-third-party.sh && \
    rm -rf /var/lib/apt/lists/* /tmp/*.txt /tmp/*.sh

# Configure development environment
RUN echo 'alias ll="ls -alF"' >> /root/.bashrc && \
    echo 'alias la="ls -A"' >> /root/.bashrc && \
    echo 'alias l="ls -CF"' >> /root/.bashrc && \
    echo 'function source_ros_ws() { if [ -f "./devel/setup.bash" ]; then source ./devel/setup.bash; elif [ -f "./install/setup.bash" ]; then source ./install/setup.bash; fi; }' >> /root/.bashrc

WORKDIR /workspace

# ==========================================
# Stage 9: Final Layer
# ==========================================
FROM dev-layer AS final

LABEL layer="05-final"

# Copy final layer dockerfile for reference
COPY --from=layer-collector /layers/05-final.dockerfile /tmp/

# Implement final layer (from 05-final/Dockerfile)
ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=${ROS_DISTRO}

# Add missing dependencies for ROS2 Jazzy and other tools
RUN add-apt-repository universe && \
    apt-get update && \
    apt-get install -y \
        lttng-tools \
        liblttng-ust-dev \
        libspdlog1.12 \
    && apt-get update && \
    apt-get upgrade -y

RUN mkdir -p /workspace/ros_ws/src /workspace/catkin_ws/src /workspace/colcon_ws/src


# Set up final workspace permissions
RUN chmod -R 755 /workspace && \
    chown -R root:root /workspace

# Create entry point script
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'set -e' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo 'export ROS_DISTRO=${ROS_DISTRO}' >> /entrypoint.sh && \
    echo 'source /opt/ros/${ROS_DISTRO}/setup.bash' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Set up display for GUI applications' >> /entrypoint.sh && \
    echo 'export DISPLAY=${DISPLAY:-:0}' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Execute command' >> /entrypoint.sh && \
    echo 'exec "$@"' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Add helpful build script
RUN echo '#!/bin/bash' > /usr/local/bin/ros-build && \
    echo 'cd /workspace' >> /usr/local/bin/ros-build && \
    echo 'if [ -d "catkin_ws/src" ] && [ "$(ls -A catkin_ws/src)" ]; then' >> /usr/local/bin/ros-build && \
    echo '  echo "Building catkin workspace..."' >> /usr/local/bin/ros-build && \
    echo '  cd catkin_ws && catkin_make' >> /usr/local/bin/ros-build && \
    echo 'fi' >> /usr/local/bin/ros-build && \
    echo 'if [ -d "colcon_ws/src" ] && [ "$(ls -A colcon_ws/src)" ]; then' >> /usr/local/bin/ros-build && \
    echo '  echo "Building colcon workspace..."' >> /usr/local/bin/ros-build && \
    echo '  cd /workspace/colcon_ws && colcon build' >> /usr/local/bin/ros-build && \
    echo 'fi' >> /usr/local/bin/ros-build && \
    chmod +x /usr/local/bin/ros-build

    
WORKDIR /workspace
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]