#!/bin/bash

######
# PART I create pipeline
######

# bob checks out alice's code
git clone git@github.com:bbesser/dvc-livedemo.git livedemo
cd livedemo
ls

# bob prepares the pipeline setup
dvc init
dvc remote add -d bertsBucket s3://dvc-livedemo.bertatcodecentric.de/dvc-livedemo
git status # check what files were created by dvc
git add .dvc # add all dvc files
git commit -m "init dvc"
git tag -a 0.0 -m "0.0 freshly initialized project with no pipeline defined, yet"
git status

# bob creates the pipeline configuration (versioned in git)
mkdir config
echo '{ "num_images" : 1000 }' > config/load.json
echo '{ "num_conv_filters" : 32 }' > config/train.json
git add config/load.json config/train.json
git commit -m "create pipeline configuration"

# bob runs the pipeline
./run_pipeline.sh
du -h
git status

# bob creates the dvc pipeline stages
git rm run_pipeline.sh
dvc run -f load.dvc -d config/load.json -o data python code/load.py
dvc run -f train.dvc -d data -d config/train.json -o model.h5 python -B code/train.py
dvc run -f evaluate.dvc -d model.h5 -M metrics.json python -B code/evaluate.py
git status
cat .gitignore

git add *.dvc metrics.json .gitignore
git commit -m "create dvc stages for alice's pipeline"

# for the sake of completeness - will not be discussed further
dvc metrics show

# tag the initial pipeline
echo "
To reproduce, \`git checkout\` a tag and then \`dvc repro evaluate.dvc\`.
" > README.md
git add README.md
git commit -m 'update readme'
git tag -a 0.1 -m "0.1 initial pipeline version"
git push origin master 0.0 0.1

######
# PART II develop pipeline
######

# alice reproduces the pipeline (partially)
git clone git@github.com:bbesser/dvc-livedemo.git livedemo
cd livedemo
git checkout 0.1
ll
dvc repro load.dvc
ll
dvc repro evaluate.dvc
ll

# alice

# alice implements model conversion
git checkout master
git reset --hard HEAD
cp /repo/code/publish.py code

# alice creates the publish stage
dvc run -f publish.dvc -d model.h5 -o model.onnx python code/publish.py
git add code/publish.py publish.dvc .gitignore
git commit -m 'create publish stage (to onnx format)'

git tag -a 0.2 -m "0.2 publish to onnx"

# TODO

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
dvc push -T

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
