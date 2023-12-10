# Stage 1: Build Stage
FROM osrf/ros:humble-desktop AS builder

# Set the working directory
WORKDIR /app

# Copy your assembly environment files into the container
COPY . /app

# Install Python dependencies and ROS 2 development tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 python3-pip curl libgl1-mesa-glx libosmesa6-dev patchelf \
    ros-humble-ament-cmake ros-humble-controller-interface && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip3 install --user numpy numpy-quaternion

# Switch to the root of your ROS2 workspace and build the package
WORKDIR /ros2_ws
COPY . /ros2_ws/src/rackki_learning
ARG ROS_DISTRO
RUN . /opt/ros/$ROS_DISTRO/setup.sh && \
    colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release && \
    colcon bundle

# Stage 2: Final Image
FROM osrf/ros:humble-desktop

# Set the working directory
WORKDIR /app

# Copy your assembly environment files into the container
COPY --from=builder /ros2_ws /ros2_ws

# Set the entry point to launch the simulation
CMD ["ros2", "launch", "rackki_learning", "simulator.launch.py"]
