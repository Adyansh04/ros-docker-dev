ARG BASE_IMAGE
FROM ${BASE_IMAGE}
ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Locales and baseline dev tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales tzdata \
    apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common \
    build-essential git cmake ninja-build gdb \
    python3-pip python3-venv python3-argcomplete \
 && locale-gen en_US en_US.UTF-8 \
 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
 && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# pip tooling (colcon, vcstool, linters)
COPY /common/pip-common.txt /tmp/pip-common.txt
RUN python3 -m pip install --no-cache-dir -r /tmp/pip-common.txt && rm -f /tmp/pip-common.txt \
 && activate-global-python-argcomplete || true

# GUI/X11 OpenGL client libs and utilities
COPY /common/gui-common.txt /tmp/gui-common.txt
RUN apt-get update && xargs -a /tmp/gui-common.txt apt-get install -y --no-install-recommends \
 && rm -rf /var/lib/apt/lists/* /tmp/gui-common.txt

ENV DISPLAY=:0
ENV XDG_RUNTIME_DIR=/tmp/runtime-root

# Configure ROS 2 repositories (Jammy/Noble etc.) via keyring + sources.list, with retries
RUN set -e; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update && apt-get install -y --no-install-recommends curl ca-certificates gnupg lsb-release; \
    mkdir -p /usr/share/keyrings; \
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg; \
    . /etc/os-release; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu ${UBUNTU_CODENAME} main" > /etc/apt/sources.list.d/ros2.list; \
    # Conservative APT robustness settings
    echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/80retries; \
    echo 'Acquire::http::Timeout "30";' > /etc/apt/apt.conf.d/80timeout; \
    echo 'Acquire::https::Timeout "30";' >> /etc/apt/apt.conf.d/80timeout; \
    echo 'Acquire::http::Pipeline-Depth "0";' > /etc/apt/apt.conf.d/80nopipeline; \
    echo 'Acquire::http::No-Cache "true";' > /etc/apt/apt.conf.d/80nocache; \
    # Retry apt update a few times to ride out 503s
    for i in 1 2 3 4 5; do \
      apt-get update && break || { echo "apt update failed ($i), retrying..."; sleep $((i*5)); }; \
    done; \
    # Per ROS docs on Jammy: upgrade before installing ROS to avoid systemd/udev removal
    apt-get -o Dpkg::Options::="--force-confnew" -y dist-upgrade || \
      apt-get -y upgrade || true; \
    # Install dev tools used by ROS workflows
    apt-get install -y --no-install-recommends ros-dev-tools; \
    rm -rf /var/lib/apt/lists/*
ARG ROS_META
RUN if [ -n "$ROS_META" ]; then apt-get update && apt-get install --fix-missing -y --no-install-recommends "$ROS_META" && rm -rf /var/lib/apt/lists/*; fi

# Initialize rosdep (no-op if not present yet)
RUN set -e; \
 if command -v rosdep >/dev/null 2>&1; then \
   if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then \
     rosdep init || true; \
   fi; \
   rosdep update || true; \
 fi

ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=1000

RUN set -e; \
    groupadd --gid "${USER_GID}" "${USERNAME}" || true; \
    useradd -m -s /bin/bash --uid "${USER_UID}" --gid "${USER_GID}" "${USERNAME}" || true; \
    apt-get update && apt-get install -y --no-install-recommends sudo bash-completion && rm -rf /var/lib/apt/lists/*; \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99-${USERNAME}; \
    \
    SNIP_FILE=/tmp/ros_bashrc_addons; \
    : > "${SNIP_FILE}"; \
    echo '# Bash completion' >> "${SNIP_FILE}"; \
    echo 'if [ -f /etc/bash_completion ]; then' >> "${SNIP_FILE}"; \
    echo '  . /etc/bash_completion' >> "${SNIP_FILE}"; \
    echo 'fi' >> "${SNIP_FILE}"; \
    echo '' >> "${SNIP_FILE}"; \
    echo '# ROS setup (auto-detect ROS1/ROS2)' >> "${SNIP_FILE}"; \
    echo 'if [ -d /opt/ros/noetic ]; then' >> "${SNIP_FILE}"; \
    echo '  source /opt/ros/noetic/setup.bash' >> "${SNIP_FILE}"; \
    echo 'elif [ -n "${ROS_DISTRO}" ] && [ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]; then' >> "${SNIP_FILE}"; \
    echo '  source "/opt/ros/${ROS_DISTRO}/setup.bash"' >> "${SNIP_FILE}"; \
    echo 'elif [ -d /opt/ros/humble ]; then' >> "${SNIP_FILE}"; \
    echo '  export ROS_DISTRO=humble' >> "${SNIP_FILE}"; \
    echo '  source /opt/ros/humble/setup.bash' >> "${SNIP_FILE}"; \
    echo 'elif [ -d /opt/ros/rolling ]; then' >> "${SNIP_FILE}"; \
    echo '  export ROS_DISTRO=rolling' >> "${SNIP_FILE}"; \
    echo '  source /opt/ros/rolling/setup.bash' >> "${SNIP_FILE}"; \
    echo 'elif [ -d /opt/ros/jazzy ]; then' >> "${SNIP_FILE}"; \
    echo '  export ROS_DISTRO=jazzy' >> "${SNIP_FILE}"; \
    echo '  source /opt/ros/jazzy/setup.bash' >> "${SNIP_FILE}"; \
    echo 'fi' >> "${SNIP_FILE}"; \
    echo '' >> "${SNIP_FILE}"; \
    echo '# colcon argcomplete' >> "${SNIP_FILE}"; \
    echo 'if command -v register-python-argcomplete >/dev/null 2>&1; then' >> "${SNIP_FILE}"; \
    echo '  eval "$(register-python-argcomplete colcon)" || true' >> "${SNIP_FILE}"; \
    echo 'fi' >> "${SNIP_FILE}"; \
    \
    touch /etc/bash.bashrc /root/.bashrc; \
    grep -q "ROS setup (auto-detect ROS1/ROS2)" /etc/bash.bashrc || cat "${SNIP_FILE}" >> /etc/bash.bashrc; \
    mkdir -p /home/${USERNAME}; touch /home/${USERNAME}/.bashrc; \
    grep -q "ROS setup (auto-detect ROS1/ROS2)" /home/${USERNAME}/.bashrc || cat "${SNIP_FILE}" >> /home/${USERNAME}/.bashrc; \
    rm -f "${SNIP_FILE}"; \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

USER ${USERNAME}
WORKDIR /home/${USERNAME}

ARG APT_EXTRAS=/dev/null
ARG PIP_EXTRAS=/dev/null
RUN if [ -s "$APT_EXTRAS" ]; then apt-get update && xargs -a "$APT_EXTRAS" apt-get install -y --no-install-recommends && rm -rf /var/lib/apt/lists/*; fi
RUN if [ -s "$PIP_EXTRAS" ]; then python3 -m pip install --no-cache-dir -r "$PIP_EXTRAS"; fi

# Clean apt caches and temp files
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
