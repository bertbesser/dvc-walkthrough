import onnxmltools
import keras

MODEL_FOLDER = "/home/dvc/livedemo/model"
model = keras.models.load_model(MODEL_FOLDER + '/model.h5')
onx = onnxmltools.convert_keras(model)
with open(MODEL_FOLDER + "/model.onnx", "wb") as f:
    f.write(onx.SerializeToString())