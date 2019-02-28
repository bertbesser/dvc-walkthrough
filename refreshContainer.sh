#!/bin/bash

MOUNT_FOLDER="$(pwd)"/mount_folder

docker stop blog-dvc
docker rm blog-dvc
docker build -t blog-dvc .
mkdir -p $MOUNT_FOLDER
docker run -d --mount type=bind,source=$MOUNT_FOLDER,target=/remote --name blog-dvc blog-dvc

if [[ "$*" =~ "build" ]]; then
  docker exec -ti blog-dvc bash -c "cd /blog-dvc; bash code/build_tutorial.sh"
fi

if [[ "$*" =~ "clone" ]]; then
  docker exec -ti blog-dvc bash -c "cd /blog-dvc; bash code/clone_tutorial.sh"
fi

if [[ "$*" =~ "bash" ]]; then
  docker exec -ti blog-dvc bash -c "cd /blog-dvc; bash"
fi
