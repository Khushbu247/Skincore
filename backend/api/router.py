from fastapi import APIRouter, UploadFile, File
from backend.utils.prediction_logger import save_prediction_log
import tensorflow as tf
from pathlib import Path
import shutil
from fastapi import HTTPException
import uuid
from datetime import datetime

from backend.app.model_loader import model
from backend.app.predictor import predict_image
from backend.app.schemas import (
    PredictionResponse,
    HealthResponse,
    ModelInfoResponse
)
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
        "project": "SkinCore AI",
        "description": "AI-powered skin disease classification API",
        "model": MODEL_NAME,
        "version": MODEL_VERSION,
        "status": "Running",
        "documentation": "/docs",
        "health_check": "/health",
        "model_info": "/model-info"
    }


# ==========================
# Health Endpoint
# ==========================

@router.get("/health", response_model=HealthResponse)
def health():

    return {
        "status": "healthy",
        "model_loaded": model is not None,
        "tensorflow_version": tf.__version__
    }


# ==========================
# Model Info Endpoint
# ==========================

@router.get("/model-info", response_model=ModelInfoResponse)
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

@router.post(
    "/predict",
    response_model=PredictionResponse,
    summary="Predict Skin Disease",
    description="Upload a skin image (JPG, JPEG or PNG) and receive the predicted skin condition, confidence score, class probabilities, model version and processing time."
)
async def predict(file: UploadFile = File(...)):

    # Allowed image types
    allowed_extensions = [".jpg", ".jpeg", ".png"]

    extension = Path(file.filename).suffix.lower()

    if extension not in allowed_extensions:
        raise HTTPException(
            status_code=400,
            detail="Only JPG, JPEG and PNG images are allowed."
        )

    # Generate unique filename
    filename = (
        f"{datetime.now().strftime('%Y%m%d_%H%M%S')}_"
        f"{uuid.uuid4().hex[:8]}"
        f"{extension}"
    )

    file_path = UPLOAD_DIR / filename

    try:
        # Save uploaded image
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # Predict
        result = predict_image(str(file_path))
        save_prediction_log(
            image_name=filename,
            result=result
        )

        return result

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )