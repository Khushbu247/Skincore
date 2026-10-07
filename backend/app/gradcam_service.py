import os
import base64
import io
import numpy as np

def generate_gradcam_heatmap(image_path: str, predicted_class_index: int) -> dict:
    """
    Optional non-blocking Grad-CAM heatmap generator.
    Returns base64 encoded PNG overlay or fallback dict if unavailable.
    """
    try:
        import tensorflow as tf
        from PIL import Image

        model_path = os.path.join("backend", "model", "best_model_finetuned.keras")
        if not os.path.exists(model_path):
            model_path = os.path.join("backend", "model", "best_model.keras")

        if not os.path.exists(model_path):
            return {
                "available": False,
                "heatmap_base64": None,
                "description": "Keras model file not found for Grad-CAM"
            }

        # Try loading Keras model
        keras_model = tf.keras.models.load_model(model_path, compile=False)

        # Preprocess image
        img = Image.open(image_path).convert("RGB").resize((224, 224))
        img_array = np.array(img, dtype=np.float32) / 255.0
        img_tensor = np.expand_dims(img_array, axis=0)

        # Find last conv layer
        last_conv_layer = None
        for layer in reversed(keras_model.layers):
            if isinstance(layer, (tf.keras.layers.Conv2D, tf.keras.layers.DepthwiseConv2D)):
                last_conv_layer = layer
                break

        if not last_conv_layer:
            return {
                "available": False,
                "heatmap_base64": None,
                "description": "Convolutional layer not identified for Grad-CAM"
            }

        grad_model = tf.keras.models.Model(
            inputs=[keras_model.inputs],
            outputs=[last_conv_layer.output, keras_model.output]
        )

        with tf.GradientTape() as tape:
            conv_outputs, predictions = grad_model(img_tensor)
            loss = predictions[:, predicted_class_index]

        grads = tape.gradient(loss, conv_outputs)
        pooled_grads = tf.reduce_mean(grads, axis=(0, 1, 2))

        conv_outputs = conv_outputs[0]
        heatmap = conv_outputs @ pooled_grads[..., tf.newaxis]
        heatmap = tf.squeeze(heatmap)

        heatmap = tf.maximum(heatmap, 0) / (tf.math.reduce_max(heatmap) + 1e-10)
        heatmap_np = heatmap.numpy()

        # Simple colormap overlay using PIL/numpy without requiring matplotlib
        heatmap_resized = Image.fromarray(np.uint8(255 * heatmap_np)).resize((224, 224), Image.BILINEAR)
        heatmap_arr = np.array(heatmap_resized)

        # Create red-yellow attention overlay on original RGB image
        overlay = np.array(img, dtype=np.uint8)
        # Apply red channel emphasis where attention is high
        overlay[:, :, 0] = np.clip(overlay[:, :, 0].astype(np.int32) + (heatmap_arr * 0.7).astype(np.int32), 0, 255).astype(np.uint8)

        buffered = io.BytesIO()
        Image.fromarray(overlay).save(buffered, format="PNG")
        img_str = base64.b64encode(buffered.getvalue()).decode("utf-8")

        return {
            "available": True,
            "heatmap_base64": f"data:image/png;base64,{img_str}",
            "description": "AI visual attention heatmap indicating regions that influenced prediction."
        }

    except Exception as e:
        return {
            "available": False,
            "heatmap_base64": None,
            "description": f"Grad-CAM generation skipped: {str(e)}"
        }
