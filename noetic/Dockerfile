# Base image with CUDA 12.6 and cuDNN for Ubuntu 20.04
FROM nvidia/cuda:12.6.3-cudnn-devel-ubuntu20.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Copy environment defaults and export them for both login and non-login shells
COPY env.list /etc/ros_env/env.list

# Default values can be overridden at build with --build-arg KEY=VALUE
ARG NVIDIA_VISIBLE_DEVICES=all
ARG NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics,video,display
ARG QT_X11_NO_MITSHM=1
ARG ROS_DISTRO=noetic
ARG ROS_DOMAIN_ID=0


ENV NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES}
ENV NVIDIA_DRIVER_CAPABILITIES=${NVIDIA_DRIVER_CAPABILITIES}
ENV QT_X11_NO_MITSHM=${QT_X11_NO_MITSHM}
ENV ROS_DISTRO=${ROS_DISTRO}
ENV ROS_DOMAIN_ID=${ROS_DOMAIN_ID}

# Section 1: Set locale
RUN apt-get update && apt-get install -y locales && \
    locale-gen en_US en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8

# Also load env.list into /etc/environment and /etc/profile.d for interactive shells
RUN awk -F= '!/^($|#)/{print $1"="$2}' /etc/ros_env/env.list >> /etc/environment && \
    awk -F= '!/^($|#)/{print "export "$1"=\""$2"\""}' /etc/ros_env/env.list > /etc/profile.d/10-ros-env.sh && \
    chmod +x /etc/profile.d/10-ros-env.sh

# Section 2: Setup ROS 1 Sources
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    ca-certificates \
    apt-transport-https \
    wget \
    bash-completion \
    apt-utils

# Add ROS 1 repository
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -

# Section 3: Install ROS 1 and other packages
RUN apt-get update && apt-get upgrade -y

# Install core ROS packages
RUN apt-get install -y --no-install-recommends --fix-missing \
    ros-${ROS_DISTRO}-desktop-full \
    python3-rosdep \
    python3-rosinstall \
    python3-rosinstall-generator \
    python3-wstool \
    build-essential \
    python3-catkin-tools

# Initialize rosdep
RUN rosdep init || true && rosdep update || true

# Copy package lists into the container
COPY apt-packages.txt pip-packages.txt ros-pkgs.txt /tmp/

# Install additional packages
RUN apt-get install -y --no-install-recommends \
    apt-transport-https apt-utils clang-format git-lfs iputils-ping libpopt0 mlocate plocate rsync unzip \
    javascript-common libjs-jquery-hotkeys libjs-jquery-isonscreen libjs-jquery-metadata libjs-jquery-tablesorter libjs-jquery-throttle-debounce \
    python3-pip python3-pip-whl python3-setuptools-whl \
    binfmt-support gfortran jq kmod lcov libasio-dev libatlas-base-dev libatlas3-base libcunit1 libcunit1-dev \
    libhidapi-libusb0 libjq1 libmnl-dev libmnl0 \
    libncurses-dev libncurses5-dev libonig5 libpcap-dev libpcap0.8-dev libpfm4 libturbojpeg \
    libv4l-0 libv4l-dev libv4l2rds0 libv4lconvert0 libx264-dev libz3-dev linuxptp \
    nlohmann-json3-dev patchelf && \
    true


# Extra Python tooling and libs
RUN python3 -m pip install -U --no-cache-dir \
    argcomplete \
    autopep8 \
    flake8 \
    flake8-blind-except \
    flake8-builtins \
    flake8-class-newline \
    flake8-comprehensions \
    flake8-deprecated \
    flake8-docstrings \
    flake8-import-order \
    flake8-quotes \
    gpustat \
    h11 \
    importlib_resources \
    networkx \
    numpy \
    numpy-quaternion \
    onnx \
    pydocstyle \
    pymongo \
    pyyaml \
    scipy \
    scikit-image \
    scikit-learn \
    setuptools_scm \
    tqdm \
    trimesh \
    virtualenv

# Install APT packages from list
RUN apt-get install -y --no-install-recommends $(grep -v '^#' /tmp/apt-packages.txt | xargs)

# Install ROS packages from list
RUN apt-get install -y --no-install-recommends $(grep -v '^#' /tmp/ros-pkgs.txt | xargs)

# Install pip and Python packages from list
RUN apt-get install -y python3-pip && \
    pip3 install --no-cache-dir -r /tmp/pip-packages.txt

# Set Python3 as default 'python'
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1


# Section 4: Install custom tools and libraries

# Install CuPy and HDBSCAN
RUN python3 -m pip install -U \
    cupy-cuda12x \
    hdbscan

# Copy and execute all installation scripts from the tools and third_party directories
COPY tools/ /tmp/tools/
COPY third_party/ /tmp/third_party/

RUN set -eux; \
    echo "--- /tmp/tools contents ---"; ls -la /tmp/tools || true; \
    for f in $(find /tmp/tools -type f -name '*.sh' | sort); do \
        echo "=== running tool: $f ==="; chmod +x "$f"; bash -x "$f"; \
    done; \
    echo "--- /tmp/third_party contents ---"; ls -la /tmp/third_party || true; \
    for f in $(find /tmp/third_party -type f -name '*.sh' | sort); do \
        echo "=== running third_party: $f ==="; chmod +x "$f"; bash -x "$f"; \
    done

# Section 5: Configure Environment
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc && \
    echo 'if [ -f /etc/bash_completion ]; then . /etc/bash_completion; fi' >> ~/.bashrc

# Section 6: Cleanup
RUN rm -rf /tmp/*

# Set default command to start a bash shell
CMD ["bash"]
