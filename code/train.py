import keras
from keras.datasets import mnist
from keras.models import Sequential
from keras.layers import Dense, Dropout, Flatten
from keras.layers import Conv2D, MaxPooling2D
from sklearn.model_selection import train_test_split
import numpy as np
import os
from scipy import misc

DATA_FOLDER = "/blog-dvc/data"
NUM_CLASSES = 10 # number of digits
BATCH_SIZE = 50

model = Sequential()
model.add(Conv2D(32, (5, 5), input_shape=(28, 28, 1), activation='relu'))
model.add(MaxPooling2D(pool_size=(2, 2)))
model.add(Dropout(0.2))
model.add(Flatten())
model.add(Dense(NUM_CLASSES, activation='softmax'))
model.compile(loss='categorical_crossentropy', optimizer='adam', metrics=['accuracy'])

X, y = [], []
for digit in range(NUM_CLASSES):
    for image in os.listdir(os.path.join(DATA_FOLDER, str(digit))):
        im = misc.imread(os.path.join(DATA_FOLDER, str(digit), image))
        X.append(im)
        y.append(digit)

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.33, random_state=42)
X_train = np.array(X_train)
y_train = np.array(y_train)
X_test = np.array(X_test)
y_test = np.array(y_test)
X_train = np.dot(X_train[...,:4], [1,0,0])
X_test = np.dot(X_test[...,:4], [1,0,0])
X_train = X_train / 255
X_test = X_test / 255
X_train = X_train.reshape(X_train.shape[0], 28, 28, 1).astype('float32')
X_test = X_test.reshape(X_test.shape[0], 28, 28, 1).astype('float32')
y_train = keras.utils.np_utils.to_categorical(y_train)
y_test = keras.utils.np_utils.to_categorical(y_test)

model.fit(np.asarray(X_train), np.asarray(y_train), batch_size=BATCH_SIZE, epochs=10, verbose=1)
score = model.evaluate(X_test, y_test, verbose=1)
print(str(model.metrics_names) + "=" + str(score))
