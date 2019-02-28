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

mkdir /blog-dvc/config
echo '{ "train_data_size" : 0.01 }' > /blog-dvc/config/preprocess.json
echo '{ "num_conv_filters" : 32 }' > /blog-dvc/config/train-config.json
git add config/preprocess.json config/train-config.json
git commit -m "add config"
dvc run -d /blog-dvc/config/preprocess.json -f preprocess.dvc -o /blog-dvc/data python /blog-dvc/code/preprocess.py
echo data >> .gitignore # this folder will be managed by dvc, git can safely ignore this folder
git add preprocess.dvc .gitignore
git commit -m "0.01 load data"
dvc run -f train.dvc -d /blog-dvc/data -d /blog-dvc/config/train-config.json -M /blog-dvc/model/metrics.json -o /blog-dvc/model/model.h5 python code/train.py
echo model/model.h5 >> .gitignore
git add train.dvc model/metrics.json .gitignore
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

git checkout master
echo '{ "train_data_size" : 0.02 }' > /blog-dvc/config/preprocess.json
dvc repro train.dvc
git add preprocess.dvc train.dvc config/preprocess.json model/metrics.json
git commit -m "0.02 data, config, and training"
git tag 0.02
git status

# dvc pipeline show --ascii train.dvc

dvc repro train.dvc # nothing happens
echo '{ "num_conv_filters" : 64 }' > /blog-dvc/config/train-config.json
dvc repro train.dvc # only retraining, and only dep/output checksums changed
dvc repro train.dvc # nothing happens
echo '{ "train_data_size" : 0.03 }' > config/preprocess.json
dvc repro train.dvc # reload data and retrain
