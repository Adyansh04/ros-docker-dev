ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG ROS_DISTRO=humble
ARG UBUNTU_VERSION=22.04

LABEL layer="ros"
LABEL description="ROS ${ROS_DISTRO} installation"
LABEL ros_distro="${ROS_DISTRO}"

ENV ROS_DISTRO=${ROS_DISTRO}
ENV DEBIAN_FRONTEND=noninteractive

# Install prerequisites
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Add ROS repository and install ROS
RUN if [ "$ROS_DISTRO" = "noetic" ]; then \
        curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - && \
        echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list && \
        apt-get update && apt-get install -y \
            ros-noetic-desktop-full \
            ros-noetic-gazebo-ros-pkgs \
            ros-noetic-gazebo-ros-control \
            ros-noetic-rqt \
            ros-noetic-rqt-common-plugins \
            ros-noetic-rviz \
            ros-noetic-robot-state-publisher \
            ros-noetic-joint-state-publisher-gui \
            ros-noetic-navigation \
            ros-noetic-move-base \
            ros-noetic-slam-gmapping; \
    else \
        curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg && \
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null && \
        apt-get update && apt-get install -y \
            ros-${ROS_DISTRO}-desktop-full \
            ros-${ROS_DISTRO}-gazebo-ros-pkgs \
            ros-${ROS_DISTRO}-gazebo-ros2-control \
            ros-${ROS_DISTRO}-rqt \
            ros-${ROS_DISTRO}-rqt-common-plugins \
            ros-${ROS_DISTRO}-rviz2 \
            ros-${ROS_DISTRO}-robot-state-publisher \
            ros-${ROS_DISTRO}-joint-state-publisher-gui \
            ros-${ROS_DISTRO}-navigation2 \
            ros-${ROS_DISTRO}-nav2-bringup \
            ros-${ROS_DISTRO}-slam-toolbox; \
    fi && \
    rm -rf /var/lib/apt/lists/*

# Install build tools and rosdep
RUN apt-get update && apt-get install -y \
    python3-rosdep \
    python3-rosinstall \
    python3-rosinstall-generator \
    python3-wstool \
    python3-colcon-common-extensions \
    python3-catkin-tools \
    && rm -rf /var/lib/apt/lists/*

# Initialize rosdep properly
RUN if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then \
        rosdep init; \
    fi && \
    rosdep update

# Set up ROS environment
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /root/.bashrc

# Create workspace structure with proper initialization
RUN mkdir -p /workspace/ros_ws/src \
             /workspace/catkin_ws/src \
             /workspace/colcon_ws/src && \
    if [ "$ROS_DISTRO" != "noetic" ]; then \
        cd /workspace/colcon_ws && \
        colcon build --symlink-install; \
    fi && \
    if [ "$ROS_DISTRO" = "noetic" ]; then \
        cd /workspace/catkin_ws && \
        catkin_make; \
    fi

WORKDIR /workspace
