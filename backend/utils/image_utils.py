import numpy as np
from tensorflow.keras.preprocessing import image

IMAGE_SIZE = (224, 224)


def preprocess_image(img_path):
    """
    Load image exactly the same way as during training.
    """

    img = image.load_img(img_path, target_size=IMAGE_SIZE)

    img_array = image.img_to_array(img)

    img_array = img_array / 255.0

    img_array = np.expand_dims(img_array, axis=0)

    return img_array