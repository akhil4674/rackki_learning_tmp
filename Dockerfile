# Stage 1: Build Stage
FROM osrf/ros:galactic-desktop AS builder

# Set the working directory
WORKDIR /app

# Fetch and add ROS GPG Key
RUN apt-get update && \
    apt-get install -y --no-install-recommends gnupg curl && \
    curl -sSL http://repo.ros2.org/repos.key | gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    gpg --batch --yes --keyserver keyserver.ubuntu.com --recv-key AD19BAB3CBF125EA && \
    gpg --batch --yes --export --armor AD19BAB3CBF125EA | gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "no-tty" >> /etc/gnupg/gpg.conf && \
    echo "use-agent" >> /etc/gnupg/gpg.conf && \
    echo "pinentry-mode loopback" >> /etc/gnupg/gpg.conf && \
    echo "deb [signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://snapshots.ros.org/humble/2023-10-11/ubuntu jammy main" > /etc/apt/sources.list.d/ros2-latest.list && \
    apt-get update --allow-releaseinfo-change && \
    apt-get install -y --no-install-recommends python3 python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*








# Stage 2: Final Image
FROM osrf/ros:galactic-desktop

# Set the working directory
WORKDIR /app

# Copy from the builder stage
COPY --from=builder /usr/share/keyrings/ros-archive-keyring.gpg /usr/share/keyrings/ros-archive-keyring.gpg

# Copy your assembly environment files into the container
COPY . /app

# Install Python dependencies
RUN pip3 install --user numpy numpy-quaternion

# Install Mujoco (assuming the installation scripts are in the same directory)
RUN chmod +x .install_mujoco.sh && \
    ./.install_mujoco.sh

# Install other dependencies for training and serving models
RUN chmod +x .install_python_dependencies.sh && \
    ./.install_python_dependencies.sh

RUN chmod +x .install_libtensorflow_cc.sh && \
    ./.install_libtensorflow_cc.sh

# Switch to the root of your ROS2 workspace and build the package
WORKDIR /ros2_ws
COPY . /ros2_ws/src/rackki_learning

RUN . /opt/ros/$ROS_DISTRO/setup.sh && \
    colcon build --packages-select rackki_learning

# Set the entry point to launch the simulation
CMD ["ros2", "launch", "rackki_learning", "simulator.launch.py"]
