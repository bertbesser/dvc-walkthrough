import numpy as np
import random
import tensorflow as tf
from keras import backend as K

# for the sake of the demo, force the same network initialization each time
# additionally, CUDA_VISIBLE_DEVICES="" PYTHONHASHSEED=0 was set
# see https://keras.io/getting-started/faq/
np.random.seed(1)
random.seed(1)
session_conf = tf.ConfigProto(intra_op_parallelism_threads=1, inter_op_parallelism_threads=1)
tf.set_random_seed(1234)
sess = tf.Session(graph=tf.get_default_graph(), config=session_conf)
K.set_session(sess)

import keras
from keras.datasets import mnist
from keras.models import Sequential
from keras.layers import Dense, Dropout, Flatten
from keras.layers import Conv2D, MaxPooling2D
from sklearn.model_selection import train_test_split
import os
from scipy import misc
import json
from prepare_train import load_train_data
from pathlib import Path

REPO_FOLDER = Path.home().as_posix() + "/livedemo"
DATA_FOLDER = REPO_FOLDER + "/data"
NUM_CLASSES = 10 # number of digits
BATCH_SIZE = 50
with open(REPO_FOLDER + '/config/train.json') as f:
    data = json.load(f)
    num_conv_filters = data["num_conv_filters"]

# define model
model = Sequential()
model.add(Conv2D(num_conv_filters, (5, 5), input_shape=(28, 28, 1), activation='relu'))
model.add(MaxPooling2D(pool_size=(2, 2)))
model.add(Flatten())
model.add(Dense(NUM_CLASSES, activation='softmax'))
model.compile(loss='categorical_crossentropy', optimizer='adam', metrics=['accuracy'])

# load training data
X, y = load_train_data()

# train
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.33, random_state=42)
history = model.fit(np.asarray(X_train), np.asarray(y_train), batch_size=BATCH_SIZE, epochs=10, verbose=1)

# generate output
model.save(REPO_FOLDER + '/model.h5')
np.savetxt("history.csv",
           np.array([history.history["loss"], history.history["acc"]]).transpose(),
           header="loss,acc",
           delimiter=",",
           comments='')
