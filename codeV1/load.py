import os
from shutil import copy
import json
from pathlib import Path

# the load stage simply copies data to the training source folder
# the amount of data is controlled by the load stage configuration

DESTINATION_FOLDER=Path.home().as_posix() + "/livedemo/data"

for digit in range(10):
    os.makedirs(os.path.join(DESTINATION_FOLDER, str(digit)), exist_ok=True)

with open(Path.home().as_posix() + '/livedemo/config/load.json') as f:
    num_images = json.load(f)["num_images"]

with open("/randomly_listed_images.txt") as f:
    images = f.read().splitlines()

for image in images[:num_images]:
    image_with_digitfolder = image[len("/image_data/"):]
    copy(image, os.path.join(DESTINATION_FOLDER, image_with_digitfolder))
