#!/bin/bash

cd /
rm -rf /dvc-walkthrough
git clone /remote/git-repo /dvc-walkthrough
cd /dvc-walkthrough
ls model # no model there :(
dvc pull -v -T
ls model # theeere it is :)
