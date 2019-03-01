#!/bin/bash

REPO_FOLDER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
MOUNT_FOLDER=$REPO_FOLDER/mount_folder

docker stop dvc-walkthrough
docker rm dvc-walkthrough
docker build -t dvc-walkthrough .
mkdir -p $MOUNT_FOLDER
docker run -d --mount type=bind,source=$MOUNT_FOLDER,target=/remote --name dvc-walkthrough dvc-walkthrough

if [[ "$*" =~ "build" ]]; then
  docker exec -ti dvc-walkthrough bash -c "cd /blog-dvc; bash code/build_tutorial.sh"
fi

if [[ "$*" =~ "clone" ]]; then
  docker exec -ti dvc-walkthrough bash -c "cd /blog-dvc; bash code/clone_tutorial.sh"
fi

if [[ "$*" =~ "bash" ]]; then
  docker exec -ti dvc-walkthrough bash -c "cd /blog-dvc; bash"
fi
