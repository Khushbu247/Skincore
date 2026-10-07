from pydantic import BaseModel
from typing import Dict, List, Optional


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


# Hybrid Analysis Schemas
class PrimaryPrediction(BaseModel):
    condition: str
    condition_display: str
    confidence: float
    model: str
    model_version: str


class SkinTypeInfo(BaseModel):
    estimated_type: str
    confidence_note: str
    source: str


class RegionObservation(BaseModel):
    region: str
    observation: str
    severity: str


class GroqAnalysisInfo(BaseModel):
    available: bool
    visual_description: str
    region_observations: List[RegionObservation] = []
    additional_findings: List[str] = []
    model_used: Optional[str] = None


class GradcamInfo(BaseModel):
    available: bool
    heatmap_base64: Optional[str] = None
    description: str


class ProcessingInfo(BaseModel):
    mobilenet_time_ms: float
    total_time_ms: float
    image_size: str


class HybridPredictionResponse(BaseModel):
    success: bool = True
    analysis_version: str = "2.0.0"
    endpoint: str = "/predict/hybrid"
    primary_prediction: PrimaryPrediction
    probabilities: Dict[str, float]
    assessment_state: str
    assessment_state_display: str
    skin_type: SkinTypeInfo
    groq_analysis: GroqAnalysisInfo
    overall_assessment: str
    needs_professional_review: bool
    safety_message: Optional[str] = None
    gradcam: GradcamInfo
    processing: ProcessingInfo
    errors: List[str] = []
