#!/usr/bin/env bash
export AWS_DEFAULT_PROFILE=besser
aws s3 rm --recursive s3://dvc-livedemo.bertatcodecentric.de/dvc-livedemo
