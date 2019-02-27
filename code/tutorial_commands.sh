#!/bin/bash

git status # this is not a git repo yet

git init # let's make it a git repo
git config user.email "bert.besser@codecentric.de"
git config user.name "Bert Besser"
git add . # prepare initial import
git commit -m "initial import"
git status

dvc init # init dvc
git status
git add . # add all dvc core files
git commit -m "init dvc"
git tag 0.00
git status

dvc run -f loaddata.dvc -o /blog-dvc/data python /blog-dvc/code/load_data.py 0.01 # run load data for version 0.01
echo data >> .gitignore # this folder will be managed by dvc, git can safely ignore this folder
git add loaddata.dvc .gitignore
git commit -m "0.01 load data"
dvc run -f train.dvc -d /blog-dvc/data -o /blog-dvc/model python code/train.py
echo model >> .gitignore
git add train.dvc .gitignore
git commit -m "0.01 train"
git tag 0.01
git status

git checkout 0.00
dvc checkout # dvc removes data and model folders
ls data # fails, since this version does not contain data
ls model # fails, since this version does not have a trained model
git checkout 0.01
ls data # still fails, since dvc did not recreate the data yet
ls model # still fails, since dvc did not recreate the model yet
dvc checkout
ls data # success, dvc restored all data
ls model # success, dvc restored the model

dvc run --overwrite-dvcfile -f loaddata.dvc -o /blog-dvc/data python /blog-dvc/code/load_data.py 0.02
dvc run --overwrite-dvcfile -f train.dvc -d /blog-dvc/data -o /blog-dvc/model python code/train.py
git add loaddata.dvc train.dvc
git commit -m "0.02 data and training"
git tag 0.02
git status
