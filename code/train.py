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
from load_data import load_data

DATA_FOLDER = "/home/dvc/walkthrough/data"
MODEL_FOLDER = "/home/dvc/walkthrough/model"
NUM_CLASSES = 10 # number of digits
BATCH_SIZE = 50
with open('/home/dvc/walkthrough/config/train.json') as f:
    data = json.load(f)
    num_conv_filters = data["num_conv_filters"]

# define model
model = Sequential()
model.add(Conv2D(num_conv_filters, (5, 5), input_shape=(28, 28, 1), activation='relu'))
model.add(MaxPooling2D(pool_size=(2, 2)))
model.add(Dropout(0.2))
model.add(Flatten())
model.add(Dense(NUM_CLASSES, activation='softmax'))
model.compile(loss='categorical_crossentropy', optimizer='adam', metrics=['accuracy'])

# load training data
X, y = load_data()

# train
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.33, random_state=42)
model.fit(np.asarray(X_train), np.asarray(y_train), batch_size=BATCH_SIZE, epochs=10, verbose=1)

# generate output
os.makedirs(MODEL_FOLDER, exist_ok=True)
model.save(MODEL_FOLDER + '/model.h5')
