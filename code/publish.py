import onnxmltools
import keras
from pathlib import Path

REPO_FOLDER = Path.home().as_posix() + "/livedemo"
model = keras.models.load_model(REPO_FOLDER + '/model.h5')
onx = onnxmltools.convert_keras(model)
with open(REPO_FOLDER + "/model.onnx", "wb") as f:
    f.write(onx.SerializeToString())