#!/bin/bash

cd /
rm -rf /blog-dvc
git clone /remote/git-repo /blog-dvc
cd /blog-dvc
ls model # no model there :(
dvc pull -v -T
ls model # theeere it is :)
