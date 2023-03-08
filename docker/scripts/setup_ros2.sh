#!/bin/bash -e 
# 参考：Docker（Windows）でROS2 Humbleを扱えるようにする
# https://qiita.com/Yuya-Shimizu/items/4f6e17d50d033c111d84 

# add the ROS deb repo to the apt sources list
apt-get update && \
apt-get install -y --no-install-recommends \
    software-properties-common && \
add-apt-repository universe && \
apt-get install -y ca-certificates \
&& apt-get clean && \
rm -rf /var/lib/apt/lists/*
curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

# install development packages for ROS
apt-get update && \
apt-get install -yq --no-install-recommends \
    gnupg2 \
    libbullet-dev \
    libpython3-dev \
    python3-colcon-common-extensions \
    python3-flake8 \
    python3-numpy \
    python3-pytest-cov \
    python3-rosdep \
    python3-vcstool \
    python3-rosinstall-generator \
    libasio-dev \
    libtinyxml2-dev \
    libcunit1-dev \
&& apt-get clean && \
rm -rf /var/lib/apt/lists/*

# Install ROS 2 Packages (Debian)
# https://docs.ros.org/en/humble/Installation/Ubuntu-Install-Debians.html#id4
apt-get update && \
apt-get install -y ros-${ROS_DISTRO}-desktop

# # Install ROS 2 Packages (Binary)
# apt-get update && \
# mkdir -p ${ROS_ROOT}/src && \
# if [ ${ROS_DISTRO} -eq "humble" ]; then
#     curl -SL https://github.com/ros2/ros2/releases/download/release-humble-20220523/ros2-humble-20220523-linux-jammy-amd64.tar.bz2 \
#     | tar -jx -C ${ROS_ROOT} --strip-components=1 \
# elif [ ${ROS_DISTRO} -eq "galactic" ]; then
#     curl -SL https://github.com/ros2/ros2/releases/download/release-galactic-20210716/ros2-galactic-20210616-linux-focal-amd64.tar.bz2 \
#     | tar -jx -C ${ROS_ROOT} --strip-components=1 \
# else
#     :
# fi
# # curl -SL https://github.com/ros2/ros2/releases/download/release-humble-20220523/ros2-humble-20220523-linux-jammy-amd64.tar.bz2 \
# # | tar -jx -C ${ROS_ROOT} --strip-components=1 \
# && apt-get clean && \
# rm -rf /var/lib/apt/lists/*
# apt-get update && \
# pip install --no-cache-dir --upgrade certifi && \
# cd ${ROS_ROOT} && \
# rosdep init && \
# rosdep update && \
# rosdep install -y \
#     --ignore-src \
#     --from-paths src \
#     --rosdistro ${ROS_DISTRO} \
#     --skip-keys "fastcdr rti-connext-dds-6.0.1 urdfdom_headers" \
# && apt-get clean && \
# rm -rf /var/lib/apt/lists/*

# install development packages for ROS, ex. MoveIt
apt-get update && \
apt-get install -yq --no-install-recommends --fix-missing \
    python3-argcomplete \
    ros-${ROS_DISTRO}-xacro \
    python3-colcon-common-extensions \
    ros-${ROS_DISTRO}-joint-state-publisher-gui \
    ros-${ROS_DISTRO}-moveit \
    ros-${ROS_DISTRO}-ros2-control \
    ros-${ROS_DISTRO}-ros2-controllers \
    ros-${ROS_DISTRO}-gazebo-ros \
    ros-${ROS_DISTRO}-rmw-cyclonedds-cpp \
&& apt-get clean && \
rm -rf /var/lib/apt/lists/*

# sed -i \
# 's/ros_env_setup="\/opt\/ros\/$ROS_DISTRO\/setup.bash"/ros_env_setup="${ROS_ROOT}\/install\/setup.bash"/g' \
# /ros_entrypoint.sh && \
# cat /ros_entrypoint.sh

# echo 'source ${ROS_ROOT}/install/setup.bash' >> ${HOME}/.bashrc
echo 'source ${ROS_ROOT}/setup.bash' >> ${HOME}/.bashrc
