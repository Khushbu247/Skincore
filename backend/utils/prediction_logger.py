import json
from pathlib import Path
from datetime import datetime

PREDICTION_DIR = Path("backend/predictions")
PREDICTION_DIR.mkdir(exist_ok=True)


def save_prediction_log(image_name: str, result: dict):
    """
    Save prediction (baseline or hybrid) as a JSON file.
    """
    timestamp = datetime.now()

    if "primary_prediction" in result:
        # Hybrid payload structure
        primary = result.get("primary_prediction", {})
        proc = result.get("processing", {})
        log = {
            "timestamp": timestamp.strftime("%Y-%m-%d %H:%M:%S"),
            "image": image_name,
            "prediction": primary.get("condition"),
            "confidence": primary.get("confidence"),
            "probabilities": result.get("probabilities", {}),
            "assessment_state": result.get("assessment_state"),
            "processing_time_ms": proc.get("total_time_ms"),
            "model_version": primary.get("model_version", "1.0.0"),
            "image_size": proc.get("image_size", "224x224"),
            "hybrid_details": {
                "skin_type": result.get("skin_type"),
                "groq_analysis": result.get("groq_analysis"),
                "needs_professional_review": result.get("needs_professional_review"),
                "gradcam_available": result.get("gradcam", {}).get("available", False)
            }
        }
    else:
        # Legacy baseline payload structure
        log = {
            "timestamp": timestamp.strftime("%Y-%m-%d %H:%M:%S"),
            "image": image_name,
            "prediction": result.get("prediction"),
            "confidence": result.get("confidence"),
            "probabilities": result.get("probabilities"),
            "processing_time_ms": result.get("processing_time_ms"),
            "model_version": result.get("model_version"),
            "image_size": result.get("image_size")
        }

    filename = f"prediction_{timestamp.strftime('%Y%m%d_%H%M%S')}.json"

    with open(PREDICTION_DIR / filename, "w") as f:
        json.dump(log, f, indent=4)