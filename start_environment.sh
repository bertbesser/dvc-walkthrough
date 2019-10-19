#!/bin/bash

SRC_FOLDER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SRC_FOLDER"

user=$1
if [ -z "$user" ]
then
  >&2 echo "username required"
  exit 1
fi

# stop and remove container
docker stop dvc-livedemo-$user
docker rm dvc-livedemo-$user

# re-build image
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg USER=$user -t dvc-livedemo-$user .

# start and login to container
docker run -d --hostname dvc-livedemo --dns=8.8.8.8 --mount type=bind,source=$SRC_FOLDER,target=/repo --name dvc-livedemo-$user dvc-livedemo-$user
docker exec --user $user -ti dvc-livedemo-$user bash -c "cd /home/$user; zsh"
