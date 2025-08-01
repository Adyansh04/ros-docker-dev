# docker/layers/04-dev/Dockerfile
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

LABEL layer="development"
LABEL description="Development tools and debugging utilities"

ENV DEBIAN_FRONTEND=noninteractive

# Install debugging and profiling tools
RUN apt-get update && apt-get install -y \
    gdb \
    valgrind \
    strace \
    ltrace \
    perf \
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
    htop \
    && rm -rf /var/lib/apt/lists/*

# Install Python development tools
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-dev \
    python3-venv \
    python3-pytest \
    python3-pytest-cov \
    python3-pytest-xdist \
    python3-pytest-mock \
    python3-black \
    python3-flake8 \
    python3-pylint \
    python3-mypy \
    python3-pudb \
    python3-line-profiler \
    python3-memory-profiler \
    && rm -rf /var/lib/apt/lists/*

# Install ROS-specific testing tools
ARG ROS_DISTRO
RUN if [ "$ROS_DISTRO" = "noetic" ]; then \
        apt-get update && apt-get install -y \
            ros-noetic-rostest \
            ros-noetic-rosunit \
            && rm -rf /var/lib/apt/lists/*; \
    else \
        apt-get update && apt-get install -y \
            ros-${ROS_DISTRO}-launch-testing \
            ros-${ROS_DISTRO}-launch-testing-ament-cmake \
            && rm -rf /var/lib/apt/lists/*; \
    fi

# Install additional development utilities
RUN apt-get update && apt-get install -y \
    git-lfs \
    doxygen \
    graphviz \
    jq \
    xmlstarlet \
    netcat \
    nmap \
    i2c-tools \
    can-utils \
    && rm -rf /var/lib/apt/lists/*

# Copy and install custom packages
COPY config/pip-requirements.txt /tmp/pip-requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/pip-requirements.txt && \
    rm /tmp/pip-requirements.txt

COPY config/apt-packages.txt /tmp/apt-packages.txt
RUN apt-get update && \
    xargs -a /tmp/apt-packages.txt apt-get install -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm /tmp/apt-packages.txt

COPY config/install-third-party.sh /tmp/install-third-party.sh
RUN chmod +x /tmp/install-third-party.sh && \
    /tmp/install-third-party.sh && \
    rm /tmp/install-third-party.sh

# Configure development environment
RUN echo 'alias ll="ls -alF"' >> /root/.bashrc && \
    echo 'alias la="ls -A"' >> /root/.bashrc && \
    echo 'alias l="ls -CF"' >> /root/.bashrc && \
    echo 'function source_ros_ws() { if [ -f "./devel/setup.bash" ]; then source ./devel/setup.bash; elif [ -f "./install/setup.bash" ]; then source ./install/setup.bash; fi; }' >> /root/.bashrc

WORKDIR /workspace
