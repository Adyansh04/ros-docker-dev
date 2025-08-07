ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG ROS_DISTRO
ARG UBUNTU_VERSION

LABEL layer="ros"
LABEL description="ROS ${ROS_DISTRO} customization"

ENV DEBIAN_FRONTEND=noninteractive

# Add missing tools not in official images
RUN apt-get update && apt-get install -y \
    python3-rosdep \
    python3-colcon-common-extensions \
    && rm -rf /var/lib/apt/lists/*

# Set up ROS environment
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /root/.bashrc

# Create workspace structure
RUN mkdir -p /workspace/ros_ws/src \
             /workspace/catkin_ws/src \
             /workspace/colcon_ws/src

WORKDIR /workspace