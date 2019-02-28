# coding: utf-8

from mlxtend.data import loadlocal_mnist
from PIL import Image
import scipy.misc as smp
import sys
import os
import numpy as np
import json

SOURCE_IMAGEDATA = "/train-images-idx3-ubyte"
SOURCE_LABELS = "/train-labels-idx1-ubyte"
DESTINATION_FOLDER = "/image_data"
WIDTH = 28
HEIGHT = 28
NUM_DATAPOINTS = 10000

if __name__ == "__main__":
    # create destination folders
    for i in range(0, 10):
        os.makedirs(os.path.join(DESTINATION_FOLDER, str(i)), exist_ok=True)

    images, labels = loadlocal_mnist(
        images_path = SOURCE_IMAGEDATA,
        labels_path = SOURCE_LABELS)

    for id, image_label in enumerate(zip(images, labels)):
        image, label = image_label[0], image_label[1]

        pixeldata = np.zeros((WIDTH, HEIGHT, 3), dtype=np.uint8)
        for i in range(HEIGHT):
            for j in range(WIDTH):
                gray_value = image[i * WIDTH + j]
                pixeldata[i, j] = [gray_value, gray_value, gray_value]

        img = Image.fromarray(pixeldata)
        img.save(os.path.join(DESTINATION_FOLDER, str(label), '{:04d}.png'.format(id)))

        if id % 100 == 0:
            print("wrote {}/{} images".format(id, NUM_DATAPOINTS))
            sys.stdout.flush()

        if id == NUM_DATAPOINTS-1:
            break
