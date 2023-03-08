#!/bin/bash -e

# TODO: User should be refactored instead of hard coded olympus

USER_NAME=olympus
CMDNAME=`basename $0`

read -t 10 -p "input for selecting ROS Distro (default: humble): " SELECT_ROS_DISTRO
case "${SELECT_ROS_DISTRO}" in
    "humble" ) SELECTED_ROS_DISTRO="humble" ;;
    "galactic" ) SELECTED_ROS_DISTRO="galactic" ;;
    * ) SELECTED_ROS_DISTRO="humble" ;;
esac

function main() {

    echo "Usage: $CMDNAME container_name host_port image_tag"

    if [ ${SELECTED_ROS_DISTRO} = "humble" ]; then
        container=${1:-"mycobot-humble"}
        host_port=${2:-"9280"}
        tag=${3:-"22.04-cu11.7-humble"}
    elif [ ${SELECTED_ROS_DISTRO} = "galactic" ]; then
        container=${1:-"mycobot-galactic"}
        host_port=${2:-"9280"}
        tag=${3:-"20.04-cu11.3-galactic"}
    else
        :
    fi

    echo "docker container name: $container"
    echo "docker host expose port: $host_port"
    echo "docker image 'ros2-cuda:$tag'"

    # echo "JupyterLab open at http://127.0.0.1:$host_port "

    docker run --gpus all -ti --init --rm \
        --hostname $(hostname) --name $container \
        -p $host_port:2980 --shm-size=16384m \
        -v $(pwd)/src:/home/$USER_NAME/workspace/src \
        -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=$DISPLAY \
        ros2-cuda:$tag

    # docker-compose up --no-recreate

}

main "$@"

