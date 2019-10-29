#!/bin/bash

######
# PART I create pipeline
######

# dave checks out vince's code
git clone git@github.com:bbesser/dvc-livedemo.git livedemo
cd livedemo
ls

# dave creates the pipeline configuration (versioned in git)
mkdir config
echo '{ "num_images" : 1000 }' > config/load.json
echo '{ "num_conv_filters" : 32 }' > config/train.json
git add config/load.json config/train.json
git commit -m "create pipeline configuration"

# dave runs the pipeline
./run_pipeline.sh
du -h
git status

# dave prepares the pipeline setup
dvc init
git status
dvc remote add -d bertsBucket s3://dvc-livedemo.bertatcodecentric.de/dvc-livedemo
git status # check what files were created by dvc
git add .dvc # add all dvc files
git commit -m "init dvc"
git tag -a 0.0 -m "0.0 freshly initialized project with no pipeline defined, yet"
git status

# dave creates the dvc pipeline stages
git rm run_pipeline.sh
dvc run -f load.dvc -d config/load.json -o data python code/load.py
dvc run -f train.dvc -d data -d config/train.json -o model.h5 python -B code/train.py
dvc run -f evaluate.dvc -d model.h5 -M metrics.json python -B code/evaluate.py
git status
cat .gitignore

git add *.dvc metrics.json .gitignore
git commit -m "create dvc stages for vince's pipeline"

# dave inspects metrics
# // just for the sake of completeness - will not be discussed further
# // - dvc can format metrics
# // - dvc can compare metrics of different pipeline versions
dvc metrics show

# dave tags the initial pipeline
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

# chloe wants to pick up on the team's work

# dave shares artifacts for 0.1 (he is still at that version)
git describe --exact-match HEAD
dvc repro --dry evaluate.dvc
dvc push

# vince imitates dave for 0.2 (he is still at that version)
git describe --exact-match HEAD
dvc repro --dry evaluate.dvc
dvc push

# chloe continues their work
git clone git@github.com:bbesser/dvc-livedemo.git livedemo
cd livedemo
git checkout 0.1
ll
dvc pull # fetches training images and model
ll
dvc repro --dry evaluate.dvc # all up to date
git checkout 0.2
dvc pull # even faster, since it only fetches the model (images are already loaded)
dvc repro --dry evaluate.dvc

######
# PART IV extend pipeline (optional)
######

# chloe cleans up working tree
git checkout master
git reset --hard HEAD

# chloe implements model conversion
cp /repo/code/publish.py code

# chloe creates the publish stage
dvc run -f publish.dvc -d model.h5 -o model.onnx python code/publish.py
git add code/publish.py publish.dvc .gitignore
git commit -m 'create publish stage (to onnx format)'
git tag -a 0.3 -m "0.3 publish to onnx"
git push origin master 0.3
dvc push

# vince inspects chloe's work
git checkout master
git reset --hard HEAD
git pull
git checkout 0.3
dvc pull
ll # model.onnx exists ...
dvc repro --dry publish.dvc # ... nothing to do
