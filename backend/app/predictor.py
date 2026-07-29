import numpy as np
import tensorflow as tf

from app.model_loader import infer
from app.preprocessing import preprocess_image
from utils.labels import CLASS_NAMES


def predict_image(image_path):

    image = preprocess_image(image_path)

    image_tensor = tf.convert_to_tensor(image)

    outputs = infer(input_layer_1=image_tensor)

    probabilities = outputs["output_0"].numpy()[0]

    predicted_index = np.argmax(probabilities)

    prediction = CLASS_NAMES[predicted_index]

    confidence = float(probabilities[predicted_index]) * 100

    probability_dict = {
        CLASS_NAMES[i]: round(float(probabilities[i]) * 100, 2)
        for i in range(len(CLASS_NAMES))
    }

    return {
        "prediction": prediction,
        "confidence": round(confidence, 2),
        "probabilities": probability_dict
    }