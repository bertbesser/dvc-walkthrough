#!/bin/bash

######
# PART I create pipeline
######

# dan checks out vince's code
git clone git@github.com:bbesser/dvc-livedemo.git livedemo
cd livedemo
ls

# dan creates the pipeline configuration (versioned in git)
mkdir config
echo '{ "num_images" : 1000 }' > config/load.json
echo '{ "num_conv_filters" : 32 }' > config/train.json
git add config/load.json config/train.json
git commit -m "create pipeline configuration"

# dan runs the pipeline
./run_pipeline.sh
du -h
git status

# dan prepares the pipeline setup
dvc init
git status
dvc remote add -d bertsBucket s3://dvc-livedemo.bertatcodecentric.de/dvc-livedemo
git status # check what files were created by dvc
git add .dvc # add all dvc files
git commit -m "init dvc"
git tag -a 0.0 -m "0.0 freshly initialized project with no pipeline defined, yet"
git status

# dan creates the dvc pipeline stages
git rm run_pipeline.sh
dvc run -f load.dvc -d config/load.json -o data python code/load.py
dvc run -f train.dvc -d data -d config/train.json -o model.h5 python -B code/train.py
dvc run -f evaluate.dvc -d model.h5 -M metrics.json python -B code/evaluate.py
git status
cat .gitignore

git add *.dvc metrics.json .gitignore
git commit -m "create dvc stages for vince's pipeline"

# dan inspects metrics
# // just for the sake of completeness - will not be discussed further
# // - dvc can format metrics
# // - dvc can compare metrics of different pipeline versions
dvc metrics show

# dan tags the initial pipeline
echo "
To reproduce, \`git checkout\` a tag and then \`dvc repro evaluate.dvc\`.
" > README.md
git add README.md
git commit -m 'update readme'
git tag -a 0.1 -m "0.1 initial pipeline version"
git push origin master 0.0 0.1

######
# PART II develop and reproduce pipeline
######

# vince reproduces the pipeline (partially)
git clone git@github.com:bbesser/dvc-livedemo.git livedemo
cd livedemo
git checkout 0.1
ll
dvc repro load.dvc
ll
dvc repro evaluate.dvc
ll

# vince does not have to repro
dvc repro evaluate.dvc

# vince improves the training configuration
git checkout master
git reset --hard HEAD
echo '{ "num_conv_filters" : 64 }' > config/train.json
dvc repro load.dvc
git status
dvc repro evaluate.dvc # also reproduces training
git status
git --no-pager diff
git add .
git commit -m 'more convolutional filters'
git tag -a 0.2 -m "0.2 more convolutional filters"
git push origin master 0.2

######
# PART III share with team
######

# clair wants to pick up on the team's work

# dan shares artifacts for 0.1 (he is still at that version)
git pull
git checkout 0.1
# git describe --exact-match HEAD
dvc repro evaluate.dvc
dvc push

# vince imitates dan
git checkout 0.2
# git describe --exact-match HEAD
dvc repro evaluate.dvc
dvc push

# clair continues their work
git clone git@github.com:bbesser/dvc-livedemo.git livedemo
cd livedemo
git checkout 0.1
ll
dvc pull # fetches training images and model
ll
dvc repro evaluate.dvc # all up to date
git checkout 0.2
dvc pull # even faster, since it only fetches the model (images are already loaded)
dvc repro evaluate.dvc

######
# PART IV extend pipeline (optional)
######

# clair implements model conversion
git checkout master
git reset --hard HEAD
cp /repo/code/publish.py code

# clair creates the publish stage
dvc run -f publish.dvc -d model.h5 -o model.onnx python code/publish.py
git add code/publish.py publish.dvc .gitignore
git commit -m 'create publish stage (to onnx format)'
git tag -a 0.3 -m "0.3 publish to onnx"
git push origin master 0.3
dvc push

# vince inspects clair's work
git checkout master
git reset --hard HEAD
git pull
git checkout 0.3
dvc pull
ll # model.onnx exists ...
dvc repro publish.dvc # ... nothing to do
