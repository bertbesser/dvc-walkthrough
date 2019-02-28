#!/bin/bash
cd /
curl -O http://yann.lecun.com/exdb/mnist/train-images-idx3-ubyte.gz
curl -O http://yann.lecun.com/exdb/mnist/train-labels-idx1-ubyte.gz
gunzip train-*-ubyte.gz
python /download_data.py
find /image_data -type f | shuf > /randomly_listed_images.txt
