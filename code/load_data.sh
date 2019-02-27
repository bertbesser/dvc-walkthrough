#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

TMP_FOLDER="/tmp/blog-dvc-data"
DATA_FOLDER="/blog-dvc/data"
FINGERPRINT_FILENAME="folder_fingerprint.txt"
VERSION=$1

(
  rm -rf $TMP_FOLDER
  mkdir -p $TMP_FOLDER
  cd $TMP_FOLDER
  curl -O http://yann.lecun.com/exdb/mnist/train-images-idx3-ubyte.gz
  curl -O http://yann.lecun.com/exdb/mnist/train-labels-idx1-ubyte.gz
  gunzip train-*-ubyte.gz
)

python $SCRIPT_DIR/load_data.py $TMP_FOLDER $DATA_FOLDER $VERSION

find $DATA_FOLDER | sort | grep -v $FINGERPRINT_FILENAME > $DATA_FOLDER/$FINGERPRINT_FILENAME
