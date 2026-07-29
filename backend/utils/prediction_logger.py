import json
from pathlib import Path
from datetime import datetime

PREDICTION_DIR = Path("backend/predictions")
PREDICTION_DIR.mkdir(exist_ok=True)


def save_prediction_log(image_name: str, result: dict):
    """
    Save every prediction as a JSON file.
    """

    timestamp = datetime.now()

    log = {
        "timestamp": timestamp.strftime("%Y-%m-%d %H:%M:%S"),
        "image": image_name,
        "prediction": result["prediction"],
        "confidence": result["confidence"],
        "probabilities": result["probabilities"],
        "processing_time_ms": result["processing_time_ms"],
        "model_version": result["model_version"],
        "image_size": result["image_size"]
    }

    filename = f"prediction_{timestamp.strftime('%Y%m%d_%H%M%S')}.json"

    with open(PREDICTION_DIR / filename, "w") as f:
        json.dump(log, f, indent=4)