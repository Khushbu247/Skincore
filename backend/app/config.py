import os
from pathlib import Path

def load_env():
    env_path = Path(__file__).resolve().parent.parent / ".env"
    if env_path.exists():
        try:
            with open(env_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue
                    if "=" in line:
                        k, v = line.split("=", 1)
                        os.environ.setdefault(k.strip(), v.strip().strip("'").strip('"'))
        except Exception as e:
            print(f"Warning: Could not read .env file: {e}")

load_env()

MODEL_NAME = "SkinCore"
MODEL_VERSION = "1.0.0"
MODEL_TYPE = "MobileNetV2"

IMAGE_SIZE = (224, 224)
UPLOAD_FOLDER = "backend/uploads"

CLASS_NAMES = [
    "acne",
    "eczema_rash",
    "pigmentation",
    "serious_condition"
]

# Groq Vision Settings
GROQ_API_KEY = os.environ.get("GROQ_API_KEY", "")
GROQ_VISION_MODEL = os.environ.get("GROQ_VISION_MODEL", "qwen-2.5-32b")

# Thresholds for 3-State Assessment
CONFIDENT_THRESHOLD = 65.0  # >= 65% indicates strong classifier signal
NORMAL_THRESHOLD = 45.0     # < 45% indicates classifier uncertainty
SERIOUS_THRESHOLD = 40.0    # > 40% serious_condition triggers safety alert