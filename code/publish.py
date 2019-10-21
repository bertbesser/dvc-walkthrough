import onnxmltools
import keras
from pathlib import Path

MODEL_FOLDER = Path.home().as_posix() + "/livedemo/model"
model = keras.models.load_model(MODEL_FOLDER + '/model.h5')
onx = onnxmltools.convert_keras(model)
with open(MODEL_FOLDER + "/model.onnx", "wb") as f:
    f.write(onx.SerializeToString())