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
from prepare_train import load_train_data
from keras.models import load_model
from pathlib import Path

REPO_FOLDER = Path.home().as_posix() + "/livedemo"

# load training data
X, y = load_train_data()
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.33, random_state=42)
model = load_model(REPO_FOLDER + '/model.h5')

model_metrics = model.evaluate(X_test, y_test, verbose=1)
metrics = {model.metrics_names[i] : model_metrics[i] for i in range(len(model_metrics))}
with open(REPO_FOLDER + '/metrics.json', 'w') as outfile:
    json.dump(metrics, outfile)
