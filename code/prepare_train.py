import keras
from keras.datasets import mnist
from keras.models import Sequential
from keras.layers import Dense, Dropout, Flatten
from keras.layers import Conv2D, MaxPooling2D
from sklearn.model_selection import train_test_split
import numpy as np
import os
from scipy import misc
import json
from pathlib import Path

NUM_CLASSES = 10
DATA_FOLDER = Path.home().as_posix() + "/livedemo/data"

def load_train_data():
    X, y = [], []
    for digit in range(NUM_CLASSES):
        for image in os.listdir(os.path.join(DATA_FOLDER, str(digit))):
            im = misc.imread(os.path.join(DATA_FOLDER, str(digit), image))
            X.append(im)
            y.append(digit)

    X = np.array(X)
    X = np.dot(X[...,:4], [1,0,0])
    X = X / 255
    X = X.reshape(X.shape[0], 28, 28, 1).astype('float32')

    y = np.array(y)
    y = keras.utils.np_utils.to_categorical(y)

    return X, y

