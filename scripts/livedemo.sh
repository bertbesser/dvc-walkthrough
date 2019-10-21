#!/bin/bash

######
# PART I create pipeline
######

# alice checks out code that she has written in the past
git clone git@github.com:bbesser/dvc-livedemo.git livedemo
cd livedemo
ls
ls code

# alice prepares the pipeline setup
dvc init
dvc remote add -d bertsBucket s3://dvc-livedemo.bertatcodecentric.de/dvc-livedemo
git status # check what files were created by dvc
git add .dvc # add all dvc files
git commit -m "init dvc"
git tag -a 0.0 -m "0.0 freshly initialized project with no pipeline defined, yet"
git status

# alice creates the pipeline configuration
mkdir config
echo '{ "num_images" : 1000 }' > config/load.json
echo '{ "num_conv_filters" : 32 }' > config/train.json
git add config/load.json config/train.json
git commit -m "create pipeline configuration"

# alice creates the load stage
dvc run -f load.dvc -d config/load.json -o data python code/load.py
git add load.dvc .gitignore
git commit -m "create load stage"
# alice creates train stage
dvc run -f train.dvc -d data -d config/train.json -o model/model.h5 python -B code/train.py
git add train.dvc model/.gitignore
git commit -m "create train stage"
# alice creates evaluate stage
dvc run -f evaluate.dvc -d model/model.h5 -M model/metrics.json python -B code/evaluate.py
git add model/metrics.json evaluate.dvc
git commit -m "create evaluate stage"

# for the sake of completeness - will not be discussed further
dvc metrics show

# tag the initial pipeline
git tag -a 0.1 -m "0.1 initial pipeline version"
git status

######
# PART II develop pipeline
######

# implement model conversion
cp /repo/code/publish.py code

# create publish stage
dvc run -f publish.dvc -d model/model.h5 -o model/model.onnx python code/publish.py
git add code/publish.py publish.dvc model/.gitignore
git commit -m 'create publish stage (to onnx format)'

git tag -a 0.2 -m "0.2 publish to onnx"

######
# PART III repro
######

# partially reproduce pipeline
echo '{ "num_conv_filters" : 64 }' > config/train.json
dvc repro load.dvc
dvc repro train.dvc
git status # inspect
git --no-pager diff # inspect
dvc repro evaluate.dvc publish.dvc
git status # inspect
git --no-pager diff # inspect
git add .
git commit -m 'more convolutional filters'
git tag -a 0.3 -m "0.3 more convolutional filters"

# fully reproduce pipeline
echo '{ "num_conv_filters" : 128 }' > config/train.json
dvc repro evaluate.dvc publish.dvc
git status # inspect
git --no-pager diff # inspect
git add .
git commit -m 'even more convolutional filters'
git tag -a 0.4 -m '0.4 even more convolutional filters'

######
# PART IV share with team
######

# as alice - share code and data with team
git push -u origin master 0.0 0.1 0.2 0.3 0.4
dvc push -v -T

# as bob - reproduce
git clone git@github.com:bbesser/dvc-livedemo.git livedemo
cd livedemo
git checkout 0.3
ls
ls data # it' not there
dvc repro load.dvc
ls data # there it is
dvc repro publish.dvc # also reproduces the train stage
ls model

# as chris - retrieve code and artifacts
git clone git@github.com:bbesser/dvc-livedemo.git livedemo
cd livedemo
ls -Al
ls -Al .dvc
dvc fetch -T
git checkout 0.3
dvc pull
dvc repro evaluate.dvc publish.dvc
