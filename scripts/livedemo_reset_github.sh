#!/bin/bash

cd /tmp
rm -rf dummy_repo
mkdir dummy_repo
cd dummy_repo
git init
git commit --allow-empty -m 'create repo'
git remote add origin git@github.com:bbesser/dvc-livedemo.git
git push -f -u origin master
git fetch --tags
git push origin --delete $(git tag -l)
git tag -d $(git tag -l)


# git tag | while read tag; do git push --delete origin $tag; git tag -d $tag; done