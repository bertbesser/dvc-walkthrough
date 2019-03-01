import os
from shutil import copy
import json

# this fake preprocessing stage simply copies data to the training source folder
# the amount of data is controlled by the preprocessing stage configuration

DESTINATION_FOLDER="/dvc-walkthrough/data"

for digit in range(10):
    os.makedirs(os.path.join(DESTINATION_FOLDER, str(digit)), exist_ok=True)

with open('/dvc-walkthrough/config/preprocess.json') as f:
    train_data_size = json.load(f)["train_data_size"]

with open("/randomly_listed_images.txt") as f:
    images = f.read().splitlines()

for image in images[:int(len(images)*train_data_size)]:
    image_with_digitfolder = image[len("/image_data/"):]
    copy(image, os.path.join(DESTINATION_FOLDER, image_with_digitfolder))
