#!/bin/bash

SRC_FOLDER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SRC_FOLDER"

# stop and remove container
docker stop dvc-livedemo
docker rm dvc-livedemo

# re-build image
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t dvc-livedemo .

# start and login to container
docker run -d --hostname dvc-livedemo --mount type=bind,source=$SRC_FOLDER,target=/repo --name dvc-livedemo dvc-livedemo
docker exec --user dvc -ti dvc-livedemo bash -c "cd /home/dvc; bash"
