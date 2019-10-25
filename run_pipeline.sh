#!/usr/bin/env bash

dvc run -f stage_name.dvc -d ... -o ... python -B code/load.py
dvc run -f stage_name.dvc -d ... -o ... python -B code/train.py
dvc run -f stage_name.dvc -d ... -o ... python -B code/evaluate.py
