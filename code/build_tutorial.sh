#!/bin/bash

export PYTHONDONTWRITEBYTECODE=1

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
git tag 0.0
git status

mkdir config
echo '{ "train_data_size" : 0.1 }' > config/preprocess.json
echo '{ "num_conv_filters" : 32 }' > config/train.json
git add config/preprocess.json config/train.json
git commit -m "add config"
dvc run -d config/preprocess.json -f preprocess.dvc -o data python code/preprocess.py
git add preprocess.dvc .gitignore
git commit -m "0.1 load data"
dvc run -f train.dvc -d data -d config/train.json -o model/model.h5 python code/train.py
git add train.dvc model/.gitignore 
git commit -m "0.1 train"
dvc run -f evaluate.dvc -d model/model.h5 -M model/metrics.json python code/evaluate.py
dvc metrics show
dvc metrics modify model/metrics.json --type json --xpath acc # set desired format first; changing it later will not apply to previously committed versions
dvc metrics show
git add model/metrics.json evaluate.dvc
git commit -m "0.1 evaluate"
git tag 0.1
git status

git checkout 0.0
dvc checkout # dvc removes data and model folders
ls data # fails, since this version does not contain data
ls model # fails, since this version does not have a trained model
git checkout 0.1
ls data # still fails, since dvc did not recreate the data yet
ls model # still fails, since dvc did not recreate the model yet
dvc checkout
ls data # success, dvc restored all data
ls model # success, dvc restored the model

git checkout master
echo '{ "train_data_size" : 0.2 }' > config/preprocess.json
dvc repro evaluate.dvc
git add preprocess.dvc train.dvc evaluate.dvc config/preprocess.json model/metrics.json
git commit -m "0.2 data, config, and training"
git tag 0.2
git status

# dvc pipeline show --ascii evaluate.dvc

dvc repro train.dvc # nothing happens
echo '{ "num_conv_filters" : 64 }' > config/train.json
dvc repro train.dvc # only retraining, and only dep/output checksums changed
dvc repro train.dvc # nothing happens
echo '{ "train_data_size" : 0.3 }' > config/preprocess.json
dvc repro train.dvc # reload data and retrain
dvc repro evaluate.dvc # only evaluation needs to be performed
git add config/preprocess.json config/train.json evaluate.dvc preprocess.dvc train.dvc model/metrics.json
git commit -m "0.3"
git tag 0.3

dvc metrics show -T
