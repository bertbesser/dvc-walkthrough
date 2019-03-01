#!/bin/bash

cd /tmp
git clone /remote/git-repo cloned
cd cloned
ls data # no training data there :(
dvc pull -T
ls data # theeere it is :)
