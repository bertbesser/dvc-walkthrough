#!/bin/bash

REPO_FOLDER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#MOUNT_FOLDER=$REPO_FOLDER/mount_folder
#mkdir -p $MOUNT_FOLDER

# remove container
docker stop dvc-livedemo
docker rm dvc-livedemo

docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t dvc-livedemo .

docker run -d --mount type=bind,source=$REPO_FOLDER,target=/repo --name dvc-livedemo dvc-livedemo
docker exec --user dvc -ti dvc-livedemo bash -c "cd /home/dvc; bash"
