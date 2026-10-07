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
    HybridPredictionResponse,
    HealthResponse,
    ModelInfoResponse,
    ChatRequest,
    ChatResponse
)
from backend.app.chatbot_service import get_chatbot_response
from backend.app.groq_vision_service import analyze_skin_image_groq
from backend.app.hybrid_analyzer import analyze_hybrid
from backend.app.gradcam_service import generate_gradcam_heatmap
from backend.app.config import (
    MODEL_NAME,
    MODEL_VERSION,
    MODEL_TYPE,
    IMAGE_SIZE,
    CLASS_NAMES
)
import asyncio
import time


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
        "model_info": "/model-info",
        "predict_legacy": "/predict",
        "predict_hybrid": "/predict/hybrid",
        "chatbot": "/chatbot/message"
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
# Predict Endpoint (Legacy Baseline)
# ==========================

@router.post(
    "/predict",
    response_model=PredictionResponse,
    summary="Predict Skin Disease (Baseline)",
    description="Upload a skin image (JPG, JPEG or PNG) and receive MobileNetV2 prediction."
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

    filename = (
        f"{datetime.now().strftime('%Y%m%d_%H%M%S')}_"
        f"{uuid.uuid4().hex[:8]}"
        f"{extension}"
    )

    file_path = UPLOAD_DIR / filename

    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

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


# ==========================
# Hybrid Predict Endpoint (New 3-State AI Analysis)
# ==========================

@router.post(
    "/predict/hybrid",
    response_model=HybridPredictionResponse,
    summary="Predict Skin Disease with Hybrid AI & Groq Vision",
    description="Upload a skin image for 3-state hybrid AI assessment (MobileNetV2 classification + Groq Vision visual analysis + optional Grad-CAM)."
)
@router.post("/api/v1/predict/hybrid", response_model=HybridPredictionResponse, include_in_schema=False)
async def predict_hybrid(file: UploadFile = File(...)):
    allowed_extensions = [".jpg", ".jpeg", ".png", ".webp"]
    extension = Path(file.filename).suffix.lower()

    if extension not in allowed_extensions:
        raise HTTPException(
            status_code=400,
            detail="Only JPG, JPEG, PNG, and WEBP images are allowed."
        )

    filename = (
        f"hybrid_{datetime.now().strftime('%Y%m%d_%H%M%S')}_"
        f"{uuid.uuid4().hex[:8]}"
        f"{extension}"
    )

    file_path = UPLOAD_DIR / filename

    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        start_time = time.time()
        file_path_str = str(file_path)

        # Run MobileNetV2 inference and Groq Vision analysis concurrently
        mobilenet_task = asyncio.to_thread(predict_image, file_path_str)
        groq_task = asyncio.to_thread(analyze_skin_image_groq, file_path_str)

        mobilenet_res, groq_res = await asyncio.gather(mobilenet_task, groq_task)

        # Determine class index for optional Grad-CAM
        pred_class_name = mobilenet_res.get("prediction", "acne")
        class_idx = 0
        if pred_class_name in CLASS_NAMES:
            class_idx = CLASS_NAMES.index(pred_class_name)

        # Non-blocking Grad-CAM task
        gradcam_res = await asyncio.to_thread(generate_gradcam_heatmap, file_path_str, class_idx)

        total_time_ms = (time.time() - start_time) * 1000.0

        hybrid_payload = analyze_hybrid(
            mobilenet_result=mobilenet_res,
            groq_result=groq_res,
            gradcam_result=gradcam_res,
            total_time_ms=total_time_ms
        )

        save_prediction_log(
            image_name=filename,
            result=hybrid_payload
        )

        return hybrid_payload

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Hybrid analysis failure: {str(e)}"
        )


# ==========================
# Chatbot Endpoint
# ==========================

@router.post(
    "/chatbot/message",
    response_model=ChatResponse,
    summary="SkinCore AI Chatbot",
    description="Ask daily skincare, skin disease, and SkinCore app questions to the Groq-powered AI assistant."
)
@router.post("/api/v1/chatbot/message", response_model=ChatResponse, include_in_schema=False)
async def chatbot_message(request: ChatRequest):
    if not request.message or not request.message.strip():
        raise HTTPException(status_code=400, detail="Message content cannot be empty.")

    history_dicts = [{"role": msg.role, "content": msg.content} for msg in request.history] if request.history else []

    reply, model_used = get_chatbot_response(request.message.strip(), history=history_dicts)

    return ChatResponse(
        reply=reply,
        status="success",
        model_used=model_used
    )
