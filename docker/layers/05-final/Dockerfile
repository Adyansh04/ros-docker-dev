# Final composition layer that adds final configurations and entry point
# This layer finalizes the development environment setup

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

LABEL layer="final"
LABEL description="Final development environment composition"

# Final environment configuration
ENV DEBIAN_FRONTEND=noninteractive

# Set up final workspace permissions and structure
RUN chmod -R 755 /workspace && \
    chown -R root:root /workspace

# Create entry point script
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'set -e' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Source ROS environment' >> /entrypoint.sh && \
    echo 'source /opt/ros/${ROS_DISTRO}/setup.bash' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Set up display for GUI applications' >> /entrypoint.sh && \
    echo 'export DISPLAY=${DISPLAY:-:0}' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Execute command' >> /entrypoint.sh && \
    echo 'exec "$@"' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Add helpful scripts
RUN echo '#!/bin/bash' > /usr/local/bin/ros-build && \
    echo 'cd /workspace' >> /usr/local/bin/ros-build && \
    echo 'if [ -f "catkin_ws/src/CMakeLists.txt" ] || [ -d "catkin_ws/src" ]; then' >> /usr/local/bin/ros-build && \
    echo '  echo "Building catkin workspace..."' >> /usr/local/bin/ros-build && \
    echo '  cd catkin_ws && catkin_make' >> /usr/local/bin/ros-build && \
    echo 'fi' >> /usr/local/bin/ros-build && \
    echo 'if [ -d "colcon_ws/src" ]; then' >> /usr/local/bin/ros-build && \
    echo '  echo "Building colcon workspace..."' >> /usr/local/bin/ros-build && \
    echo '  cd colcon_ws && colcon build' >> /usr/local/bin/ros-build && \
    echo 'fi' >> /usr/local/bin/ros-build && \
    chmod +x /usr/local/bin/ros-build

# Final workspace setup
WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
