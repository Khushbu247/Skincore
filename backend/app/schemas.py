from pydantic import BaseModel
from typing import Dict, List, Optional, Any


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


# Recommendation System Schemas
class RecommendationRequest(BaseModel):
    user_id: Optional[str] = "guest"
    questionnaire_report_id: Optional[str] = None
    questionnaire_answers: Optional[Dict[str, Any]] = None
    latest_skin_analysis_report_id: Optional[str] = None
    latest_skin_analysis: Optional[Dict[str, Any]] = None
    force_refresh: bool = False


class RecommendedProductItem(BaseModel):
    product_id: str
    name: str
    brand: str
    category: str
    description: str
    price_inr: float
    price_band: str  # 'budget', 'mid_range', 'premium'
    image_url: str
    buy_url: str
    key_ingredients: List[str] = []
    suitability_score: float  # 0 to 100 compatibility score
    suitability_badge: str  # 'Highly Suitable', 'Suitable', 'Potentially Suitable'
    usage_time: str  # 'AM', 'PM', 'AM/PM'
    why_it_works: str
    how_to_use: str
    warnings_or_conflicts: List[str] = []
    source: str = "dynamic_search"


class CategoryIngredientGuidance(BaseModel):
    category: str
    recommended_actives: List[str] = []
    avoided_ingredients: List[str] = []
    rationale: str
    usage_time: str
    how_to_use: str
    safety_warnings: List[str] = []


class ProductRecommendationResponse(BaseModel):
    status: str = "success"  # 'success', 'missing_prerequisites', 'error'
    cache_key: str
    is_cached: bool = False
    skin_type_summary: str = "Combination"
    summary_ai_insight: str
    serious_condition_detected: bool = False
    medical_warning_banner: Optional[str] = None
    category_guidance: List[CategoryIngredientGuidance] = []
    products: List[RecommendedProductItem] = []
    missing_prerequisites: List[str] = []
    error_message: Optional[str] = None


