from fastapi import APIRouter, UploadFile, File
import tensorflow as tf
from pathlib import Path
import shutil

from backend.app.model_loader import model
from backend.app.predictor import predict_image

from backend.app.config import (
    MODEL_NAME,
    MODEL_VERSION,
    MODEL_TYPE,
    IMAGE_SIZE,
    CLASS_NAMES
)

router = APIRouter()
UPLOAD_DIR = Path("backend/uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

# ==========================
# Home Endpoint
# ==========================

@router.get("/")
def home():

    return {
        "message": "Welcome to SkinCore API",
        "status": "Running"
    }


# ==========================
# Health Endpoint
# ==========================

@router.get("/health")
def health():

    return {
        "status": "healthy",
        "model_loaded": model is not None,
        "tensorflow_version": tf.__version__
    }


# ==========================
# Model Info Endpoint
# ==========================

@router.get("/model-info")
def model_info():

    return {
        "model_name": MODEL_NAME,
        "version": MODEL_VERSION,
        "architecture": MODEL_TYPE,
        "image_size": IMAGE_SIZE,
        "classes": CLASS_NAMES
    }

# ==========================
# Predict Endpoint
# ==========================

@router.post("/predict")
async def predict(file: UploadFile = File(...)):

    # Save uploaded image
    file_path = UPLOAD_DIR / file.filename

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # Run prediction
    result = predict_image(str(file_path))

    return result
