from typing import Dict, Any, Optional, List
from backend.app.config import SERIOUS_THRESHOLD
from backend.app.normal_skin_detector import determine_assessment_state

CONDITION_DISPLAY_NAMES = {
    "acne": "Acne",
    "eczema_rash": "Eczema / Rash",
    "pigmentation": "Pigmentation",
    "serious_condition": "Possible Serious Condition"
}

def analyze_hybrid(
    mobilenet_result: Dict[str, Any],
    groq_result: Dict[str, Any],
    gradcam_result: Optional[Dict[str, Any]] = None,
    total_time_ms: float = 0.0
) -> Dict[str, Any]:
    """
    Merges MobileNetV2 classification + Groq Vision qualitative analysis + Grad-CAM heatmap
    into a structured 3-state hybrid response payload.
    """
    predicted_class = mobilenet_result.get("prediction", "acne")
    confidence = float(mobilenet_result.get("confidence", 0.0))
    probabilities = mobilenet_result.get("probabilities", {})
    
    # Format primary prediction
    primary_prediction = {
        "condition": predicted_class,
        "condition_display": CONDITION_DISPLAY_NAMES.get(predicted_class, predicted_class.title()),
        "confidence": round(confidence, 2),
        "model": "MobileNetV2",
        "model_version": mobilenet_result.get("model_version", "1.0.0")
    }

    # Ensure probabilities are rounded
    formatted_probs = {
        k: round(float(v), 2) for k, v in probabilities.items()
    }

    # Determine 3-state assessment classification
    assessment_state, assessment_state_display = determine_assessment_state(
        primary_prediction=primary_prediction,
        probabilities=formatted_probs,
        groq_analysis=groq_result
    )

    # Serious condition safety handling
    serious_prob = float(formatted_probs.get("serious_condition", 0.0))
    groq_red_flags = groq_result.get("red_flags_present", False)
    
    needs_professional_review = False
    safety_message = None

    if serious_prob >= SERIOUS_THRESHOLD or groq_red_flags:
        needs_professional_review = True
        safety_message = (
            "Elevated risk features or serious skin condition detected. "
            "This AI tool cannot provide a medical diagnosis. "
            "Please seek prompt evaluation from a qualified dermatologist or medical practitioner."
        )

    # Construct overall summary assessment
    visual_desc = groq_result.get("visual_description", "")
    if assessment_state == "normal_appearing":
        overall_assessment = (
            "Visual analysis indicates normal-appearing skin with no obvious severe pathological lesions. "
            "If you experience persistent symptoms, consult a doctor."
        )
    elif assessment_state == "uncertain":
        overall_assessment = (
            "The AI analysis is uncertain. Image features may be ambiguous or captured in poor lighting. "
            "Consider retaking a clear photo in daylight or consulting a dermatologist for evaluation."
        )
    else:
        cond_display = primary_prediction["condition_display"]
        overall_assessment = (
            f"AI classifier identified features consistent with {cond_display} ({confidence:.1f}% confidence). "
        )
        if visual_desc:
            overall_assessment += f"Visual examination notes: {visual_desc}"
        else:
            overall_assessment += "Please refer to the detailed probability breakdown."

    # Grad-CAM formatting (non-blocking)
    if not gradcam_result:
        gradcam_result = {
            "available": False,
            "heatmap_base64": None,
            "description": "Grad-CAM visual attention heatmap unavailable."
        }

    # Error gathering
    errors: List[str] = []
    if groq_result.get("error"):
        errors.append(f"Groq Vision: {groq_result.get('error')}")

    # Build response dictionary
    response_payload = {
        "success": True,
        "analysis_version": "2.0.0",
        "endpoint": "/predict/hybrid",
        "primary_prediction": primary_prediction,
        "probabilities": formatted_probs,
        "assessment_state": assessment_state,
        "assessment_state_display": assessment_state_display,
        "skin_type": {
            "estimated_type": groq_result.get("skin_type", "unknown"),
            "confidence_note": "Visual feature estimation via Groq AI",
            "source": "groq_vision" if groq_result.get("available") else "none"
        },
        "groq_analysis": {
            "available": groq_result.get("available", False),
            "visual_description": visual_desc,
            "region_observations": groq_result.get("region_observations", []),
            "additional_findings": groq_result.get("additional_findings", []),
            "model_used": groq_result.get("model_used")
        },
        "overall_assessment": overall_assessment,
        "needs_professional_review": needs_professional_review,
        "safety_message": safety_message,
        "gradcam": gradcam_result,
        "processing": {
            "mobilenet_time_ms": round(float(mobilenet_result.get("processing_time_ms", 0.0)), 2),
            "total_time_ms": round(total_time_ms, 2),
            "image_size": mobilenet_result.get("image_size", "224x224")
        },
        "errors": errors
    }

    return response_payload
