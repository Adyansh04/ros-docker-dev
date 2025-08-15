# Base image with CUDA 13.0 and cuDNN for Ubuntu 22.04
FROM nvidia/cuda:13.0.0-cudnn-devel-ubuntu22.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Copy environment defaults and export them for both login and non-login shells
COPY env.list /etc/ros_env/env.list

# Default values can be overridden at build with --build-arg KEY=VALUE
ARG NVIDIA_VISIBLE_DEVICES=all
ARG NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics,video,display
ARG QT_X11_NO_MITSHM=1
ARG ROS_DISTRO=humble
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

# Section 2: Setup ROS 2 Sources
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    ca-certificates \
    apt-transport-https \
    wget \
    bash-completion \
    apt-utils && \
    add-apt-repository universe

# Install ros-apt-source package to manage ROS repositories
RUN export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}') && \
    curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo $VERSION_CODENAME)_all.deb" && \
    dpkg -i /tmp/ros2-apt-source.deb && \
    rm /tmp/ros2-apt-source.deb

# Section 3: Install ROS 2, Gazebo, and other packages
RUN apt-get update && apt-get upgrade -y

# Install core ROS packages
RUN apt-get install -y --no-install-recommends --fix-missing \
    ros-${ROS_DISTRO}-desktop-full \
    ros-dev-tools \
    ros-${ROS_DISTRO}-ros-gz

# Copy package lists into the container
COPY apt-packages.txt pip-packages.txt ros-pkgs.txt /tmp/

# Install additional packages
RUN apt-get install -y --no-install-recommends \
    apt-transport-https apt-utils clang-format clang-format-14 git-lfs iputils-ping libclang-cpp14 libpopt0 liburing2 mlocate plocate rsync unzip \
    javascript-common libjs-jquery-hotkeys libjs-jquery-isonscreen libjs-jquery-metadata libjs-jquery-tablesorter libjs-jquery-throttle-debounce \
    python3-cov-core python3-coverage python3-nose2 python3-pip python3-pip-whl python3-setuptools-whl \
    binfmt-support gfortran jq kmod lcov libasio-dev libatlas-base-dev libatlas3-base libcommon-sense-perl libcunit1 libcunit1-dev \
    libgd-perl libhidapi-libusb0 libjq1 libjson-perl libjson-xs-perl libmnl-dev libmnl0 \
    libncurses-dev libncurses5-dev libonig5 libpcap-dev libpcap0.8-dev libperlio-gzip-perl libpfm4 libturbojpeg \
    libtypes-serialiser-perl libv4l-0 libv4l-dev libv4l2rds0 libv4lconvert0 libx264-dev libz3-dev linuxptp \
    llvm-14 llvm-14-dev llvm-14-linker-tools llvm-14-runtime llvm-14-tools nlohmann-json3-dev patchelf && \
    true


# Extra Python tooling and libs  you requested
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
    echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" >> ~/.bashrc && \
    echo 'if [ -f /etc/bash_completion ]; then . /etc/bash_completion; fi' >> ~/.bashrc

# Section 6: Cleanup
RUN rm -rf /tmp/*

# Set default command to start a bash shell
CMD ["bash"]