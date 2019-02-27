# coding: utf-8

from mlxtend.data import loadlocal_mnist
from PIL import Image
import scipy.misc as smp
import sys
import os
import numpy as np
import json

data_folder = "/blog-dvc/data"
with open('/blog-dvc/config/data-config.json') as f:
    data = json.load(f)
    train_data_size = data["train_data_size"]

def create_destination_folders_if_necessary():
    for i in range(0, 10):
        os.makedirs(os.path.join(data_folder, str(i)), exist_ok=True)

if __name__ == "__main__":
    create_destination_folders_if_necessary()

    X, Y = loadlocal_mnist(
        images_path = '/train-images-idx3-ubyte',
        labels_path = '/train-labels-idx1-ubyte')

    for k, xy in enumerate(zip(X, Y)):
        x, y = xy[0], xy[1]

        pixeldata = np.zeros((28, 28, 3), dtype=np.uint8)
        for i in range(28):
            for j in range(28):
                gray_value = x[i * 28 + j]
                pixeldata[i, j] = [gray_value, gray_value, gray_value]

        img = Image.fromarray(pixeldata)
        img.save(os.path.join(data_folder, str(y), str(k) + '.png'))

        if k % 100 == 0:
            print("wrote {}/{} images".format(k, len(Y)))

        if k >= len(X) * train_data_size:
            break
