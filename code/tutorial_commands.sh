#!/bin/bash
git status # this is not a git repo yet
git init # let's make it a git repo
git config user.email "you@example.com"
git config user.name "Your Name"
git add . # prepare initial import
git commit -m "initial import"
git status
dvc init # init dvc
git status
git add . # add all dvc core files
git commit -m "init dvc"
dvc run -f loaddata.dvc -o /blog-dvc/data python /blog-dvc/code/load_data.py 0.01 # run load data for version 0.01
echo data >> .gitignore # this folder will be managed by dvc, git can safely ignore this folder
git add loaddata.dvc .gitignore
git commit -m "0.01 load data"
git checkout HEAD^1 # previous commit
dvc checkout # dvc removes data folder
ls data # fails, since this version does not contain data
git checkout master
ls data # still fails, since dvc did not recreate the data yet
dvc checkout
ls data # success, dvc restored all data
