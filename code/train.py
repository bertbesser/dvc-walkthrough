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
MODEL_FOLDER = "/blog-dvc/model"
NUM_CLASSES = 10 # number of digits
BATCH_SIZE = 50

# define model
model = Sequential()
model.add(Conv2D(32, (5, 5), input_shape=(28, 28, 1), activation='relu'))
model.add(MaxPooling2D(pool_size=(2, 2)))
model.add(Dropout(0.2))
model.add(Flatten())
model.add(Dense(NUM_CLASSES, activation='softmax'))
model.compile(loss='categorical_crossentropy', optimizer='adam', metrics=['accuracy'])

# load training data
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

# train
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.33, random_state=42)
model.fit(np.asarray(X_train), np.asarray(y_train), batch_size=BATCH_SIZE, epochs=10, verbose=1)

# generate output
os.makedirs(MODEL_FOLDER, exist_ok=True)
model.save(MODEL_FOLDER + '/model.h5')

score = model.evaluate(X_test, y_test, verbose=1)
print(str(model.metrics_names) + "=" + str(score))
