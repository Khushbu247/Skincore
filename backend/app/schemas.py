from pydantic import BaseModel
from typing import Dict, List


class PredictionResponse(BaseModel):
    prediction: str
    confidence: float
    probabilities: Dict[str, float]
    model_version: str
    image_size: str
    processing_time_ms: float


class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
    tensorflow_version: str


class ModelInfoResponse(BaseModel):
    model_name: str
    version: str
    architecture: str
    image_size: List[int]
    classes: List[str]


class ChatMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    message: str
    history: List[ChatMessage] = []


class ChatResponse(BaseModel):
    reply: str
    status: str = "success"
    model_used: str = "groq-llama"