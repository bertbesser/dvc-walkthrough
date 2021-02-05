#!/usr/bin/env bash
SRC_FOLDER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "======= resetting github repo"
$SRC_FOLDER/livedemo_reset_github_repo.sh

echo "======= resetting s3 bucket"
$SRC_FOLDER/livedemo_reset_s3_bucket.sh

echo "======= resetting fake remote"
$SRC_FOLDER/livedemo_reset_fake_remote.sh
