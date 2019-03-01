#!/bin/bash

REPO_FOLDER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
MOUNT_FOLDER=$REPO_FOLDER/mount_folder
mkdir -p $MOUNT_FOLDER

docker stop dvc-walkthrough
docker rm dvc-walkthrough
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t dvc-walkthrough .
docker run -d --mount type=bind,source=$MOUNT_FOLDER,target=/remote --name dvc-walkthrough dvc-walkthrough

if [[ "$*" =~ "build" ]]; then
  rm -rf $MOUNT_FOLDER/*
  docker exec --user dvc -ti dvc-walkthrough bash -c "cd /dvc-walkthrough; bash code/build_tutorial.sh"
fi

if [[ "$*" =~ "clone" ]]; then
  docker exec --user dvc -ti dvc-walkthrough bash -c "cd /dvc-walkthrough; bash code/clone_tutorial.sh"
fi

if [[ "$*" =~ "bash" ]]; then
  docker exec --user dvc -ti dvc-walkthrough bash -c "cd /dvc-walkthrough; bash"
fi
