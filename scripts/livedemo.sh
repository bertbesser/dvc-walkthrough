#!/bin/bash

######
# PART I create pipeline
######

git clone git@github.com:bbesser/dvc-livedemo.git livedemo
cd livedemo
# verify its fresh
git fetch --tags


cp -r /repo/codeV1 code
cat code/*
git add code
git commit -m "import code"
git status

dvc init # init dvc
git status # check what files were created by dvc
git add .dvc # add all dvc core files
git commit -m "init dvc"
git tag -a 0.0 -m "0.0 freshly initialized project with no pipeline defined, yet"
git status

# prepare pipeline configuration
mkdir config
echo '{ "num_images" : 1000 }' > config/load.json
echo '{ "num_conv_filters" : 32 }' > config/train.json
git add config/load.json config/train.json
git commit -m "create pipeline config"

# configure three pipeline stages: load, train, and evaluate
# stage load
dvc run -f load.dvc -d config/load.json -o data python code/load.py
git add load.dvc .gitignore
git commit -m "create load stage"
# stage train
dvc run -f train.dvc -d data -d config/train.json -o model/model.h5 python -B code/train.py
git add train.dvc model/.gitignore
git commit -m "create train stage"
# stage evaluate
dvc run -f evaluate.dvc -d model/model.h5 -M model/metrics.json python -B code/evaluate.py
git add model/metrics.json evaluate.dvc
git commit -m "create evaluate stage"

dvc metrics show # show entire contents of metrics file
dvc metrics modify model/metrics.json --type json --xpath acc # set desired compact format; changing it here will apply to previously committed versions
dvc metrics show

git add evaluate.dvc
git commit -m 'configure metrics'

# tag the first pipeline config
git tag -a 0.1 -m "0.1 initial pipeline version"
git status

######
# PART II develop pipeline
######

cp /repo/codeV2/* code/.
dvc run -f publish.dvc -d model/model.h5 -o model/model.onnx python code/publish.py
git add code/publish.py publish.dvc model/.gitignore
git commit -m 'create publish stage (to onnx format)'
git tag -a 0.2 -m "0.2 publish onnx"

######
# PART III repro
######

# partially reproduce pipeline
echo '{ "num_conv_filters" : 64 }' > config/train.json
dvc repro load.dvc
dvc repro train.dvc
git status # inspect
git diff # inspect
dvc repro evaluate.dvc
dvc repro publish.dvc
git status # inspect
git diff # inspect
git add .
git commit -m 'more convolutional filters'
git tag -a 0.3 -m "0.3 more convolutional filters"

# fully reproduce pipeline
echo '{ "num_conv_filters" : 128 }' > config/train.json
dvc repro evaluate.dvc publish.dvc
git status # inspect
git diff # inspect
git add .
git commit -m 'even more convolutional filters'
git tag -a 0.4 -m '0.4 even more convolutional filters'

##########
# OPTIONAL metrics
##########

# compare metrics for all tags, i.e. for all pipeline versions
dvc metrics show -T

######
# PART IV share with team
######

dvc 
git push -u origin master 0.0 0.1 0.2 0.3 0.4


# setup dvc remote for pushing the cache to
mkdir /remote/dvc-cache
dvc remote add -d fake_remote /remote/dvc-cache
git add .dvc/config # save remote configuration, such that cached data can be pulled from it when your team colleagues checkout the git repo
git commit -m "configure remote"
dvc push -v -T # this is where dvc pushes cached data to the remote (for all tags)

# push git repo to remote, in order to prepare part two of the tutorial
git remote add origin /remote/git-repo
(mkdir /remote/git-repo && cd /remote/git-repo && git init --bare)
git push -u origin master
git push -u origin 0.1
git push -u origin 0.2
git push -u origin 0.3

