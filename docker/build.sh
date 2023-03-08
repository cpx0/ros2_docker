#!/bin/bash -e

read -t 10 -p "input for selecting ROS Distro (default: humble): " SELECT_ROS_DISTRO
case "${SELECT_ROS_DISTRO}" in
    "humble" ) SELECTED_ROS_DISTRO="humble" ;;
    "galactic" ) SELECTED_ROS_DISTRO="galactic" ;;
    * ) SELECTED_ROS_DISTRO="humble" ;;
esac

if [ ${SELECTED_ROS_DISTRO} = "humble" ]; then
    tag=${1:-"22.04-cu11.7-humble"}
    echo "docker image 'nvcr.io/nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04'"
elif [ ${SELECTED_ROS_DISTRO} = "galactic" ]; then
    tag=${1:-"20.04-cu11.3-galactic"}
    echo "docker image 'nvcr.io/nvidia/cuda:11.3.1-cudnn8-devel-ubuntu20.04'"
else
    :
fi

docker build \
    -m 8g --shm-size 8192m \
    -t ros2-cuda:$tag \
    -f ./docker/Dockerfile.${SELECTED_ROS_DISTRO} \
    .
