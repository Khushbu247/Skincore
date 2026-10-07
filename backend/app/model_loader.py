import tensorflow as tf
from pathlib import Path

MODEL_DIR = Path(__file__).resolve().parent.parent / "model" / "skincore_savedmodel"

print("=" * 60)
print("Loading SkinCore SavedModel...")
print(MODEL_DIR)

# Load SavedModel
model = tf.saved_model.load(str(MODEL_DIR))

print("[OK] Model loaded successfully!")

# Get serving function
infer = model.signatures["serving_default"]

print("\nAvailable signatures:")
print(model.signatures.keys())

print("\nInput Signature:")
print(infer.structured_input_signature)

print("\nOutput Signature:")
print(infer.structured_outputs)

print("=" * 60)