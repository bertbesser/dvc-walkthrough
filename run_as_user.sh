#!/bin/bash

SRC_FOLDER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SRC_FOLDER"

function ask_yes_or_no() {
    read -p "$1 ([y]es or [N]o): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|yes) echo "yes" ;;
        *)     echo "no" ;;
    esac
}

user=$1
if [ -z "$user" ]
then
  >&2 echo "username required"
  exit 1
fi

promptcolor="ffffff"
if [ "$user" == 'dave' ]
then
  promptcolor="27aec7"
elif [ "$user" == 'vince' ]
then
  promptcolor="8a6cb6"
elif [ "$user" == 'chloe' ]
then
  promptcolor="e85e3a"
fi

reset=$2
if [ "$reset" == "--reset" ]
then
    if [ "no" == $(ask_yes_or_no "Really reset ${user}'s dvc-livedemo container?") ]
    then
        exit
    else
        # stop and remove container
        docker stop dvc-livedemo-$user
        docker rm dvc-livedemo-$user

        # re-build image
        docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg USER=$user --build-arg PROMPT_COLOR=$promptcolor -t dvc-livedemo-$user .

        # start container
        FAKE_REMOTE=/tmp/dvc-fake-remote
        mkdir -p $FAKE_REMOTE
        DVC_LIVEDEMO_SHARE=/tmp/dvc-livedemo-share
        mkdir -p $DVC_LIVEDEMO_SHARE
        docker run -d --hostname dvc --dns=8.8.8.8 --mount type=bind,source=$FAKE_REMOTE,target=/dvc-fake-remote --mount type=bind,source=$SRC_FOLDER,target=/repo --mount type=bind,source=$DVC_LIVEDEMO_SHARE,target=/dvc-livedemo-share --name dvc-livedemo-$user dvc-livedemo-$user
    fi
fi


# login to container
docker exec --user $user -ti dvc-livedemo-$user bash -c "cd /home/$user; zsh"
