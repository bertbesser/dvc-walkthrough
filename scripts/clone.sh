#!/bin/bash

cd /home/dvc
git clone /remote/git-repo walkthrough-cloned
cd walkthrough-cloned
ls data # no training data there :(
dvc pull -T
ls data # theeere is our training data :)
