from fastapi import APIRouter, HTTPException
from backend.app.schemas import RecommendationRequest, ProductRecommendationResponse
from backend.app.product_recommendation_service import generate_recommendations

recommendation_router = APIRouter(
    prefix="/api/v1/recommendations",
    tags=["Product Recommendations"]
)

@recommendation_router.post(
    "/generate",
    response_model=ProductRecommendationResponse,
    summary="Generate Dynamic AI Product Recommendations",
    description="Analyzes Questionnaire & AI Skin Analysis reports to produce ingredient-focused dynamic product recommendations with deterministic suitability scoring."
)
async def generate_product_recommendations(request: RecommendationRequest):
    try:
        response = generate_recommendations(request)
        return response
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate product recommendations: {str(e)}"
        )
