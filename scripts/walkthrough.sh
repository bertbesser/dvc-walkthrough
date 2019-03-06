#!/bin/bash

git status # this is not a git repo yet

git init # let's make it a git repo
git config user.email "bert.besser@codecentric.de"
git config user.name "bbesser"
git add code # prepare initial import
git commit -m "init repo"
git status

dvc init # init dvc
git status # check what files were created by dvc
git add .dvc # add all dvc core files
git commit -m "init dvc"
git tag -a 0.0 -m "freshly initialized with no pipeline defined, yet"
git status

# prepare pipeline configuration
mkdir config
echo '{ "num_images" : 1000 }' > config/load.json
echo '{ "num_conv_filters" : 32 }' > config/train.json
git add config/load.json config/train.json
git commit -m "init config"

# configure three pipeline stages: load, train, and evaluate
# stage load
dvc run -f load.dvc -d config/load.json -o data python code/load.py
git add load.dvc .gitignore
git commit -m "init load stage"
# stage train
dvc run -f train.dvc -d data -d config/train.json -o model/model.h5 python -B code/train.py
git add train.dvc model/.gitignore 
git commit -m "init train stage"
# stage evaluate
dvc run -f evaluate.dvc -d model/model.h5 -M model/metrics.json python -B code/evaluate.py
git add model/metrics.json evaluate.dvc
git commit -m "init evaluate stage"
# tag the first pipeline config
git tag -a 0.1 -m "initial pipeline version 0.1"
git status

# you can run this command to display the pipeline in the shell
# dvc pipeline show --ascii evaluate.dvc

dvc metrics show # show entire contents of metrics file
dvc metrics modify model/metrics.json --type json --xpath acc # set desired compact format; changing it here will apply to previously committed versions
dvc metrics show

# change to initial tag, when no pipeline and no data were present
git checkout 0.0
dvc checkout # dvc removes data and model
ls data # fails, since this version does not contain data
ls model # fails, since this version does not have a trained model
git checkout 0.1
ls data # still fails, since dvc did not recreate the data yet
ls model # still fails, since dvc did not recreate the model yet
dvc checkout
ls data # success, dvc restored all data
ls model # success, dvc restored the model

# setup next version of pipeline
git checkout master
echo '{ "num_images" : 2000 }' > config/load.json
dvc repro evaluate.dvc # dvc takes care of running all necessary stages, including the evaluation stage
git add load.dvc train.dvc evaluate.dvc config/load.json model/metrics.json # version new pipeline
git commit -m "0.2 more training data"
git tag -a 0.2 -m "0.2 more training data"
git status

# dummy, for educational purposes ;)
dvc repro train.dvc # nothing happens, since pipeline was not reconfigured since last commit

# partially reproduce pipeline
echo '{ "num_conv_filters" : 64 }' > config/train.json
dvc repro train.dvc # only retraining
echo '{ "num_images" : 3000 }' > config/load.json
dvc repro train.dvc # reload data and retrain
dvc repro evaluate.dvc # only evaluation needs to be performed, since already retrained
git add config/load.json config/train.json evaluate.dvc load.dvc train.dvc model/metrics.json
git commit -m "0.3 more training data, more convolutions"
git tag -a 0.3 -m "0.3 more training data, more convolutions"

# compare metrics for all tags, i.e. for all pipeline versions
dvc metrics show -T

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


