import time
import numpy as np
import tensorflow as tf

from backend.app.model_loader import infer
from backend.app.preprocessing import preprocess_image
from backend.utils.labels import CLASS_NAMES


def predict_image(image_path):

    start = time.time()

    # Preprocess image
    img = preprocess_image(image_path)

    # Convert to Tensor
    img_tensor = tf.convert_to_tensor(img, dtype=tf.float32)

    # Run inference using SavedModel signature
    outputs = infer(input_layer_1=img_tensor)

    # Extract predictions
    prediction = outputs["output_0"].numpy()[0]

    confidence = float(np.max(prediction))

    predicted_class = CLASS_NAMES[np.argmax(prediction)]

    probabilities = {
        CLASS_NAMES[i]: round(float(prediction[i]) * 100, 2)
        for i in range(len(CLASS_NAMES))
    }

    end = time.time()

    return {
        "prediction": predicted_class,
        "confidence": round(confidence * 100, 2),
        "probabilities": probabilities,
        "processing_time_ms": round((end - start) * 1000, 2)
    }