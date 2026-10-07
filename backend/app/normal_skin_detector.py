from typing import Dict, Any, Tuple
from backend.app.config import CONFIDENT_THRESHOLD, NORMAL_THRESHOLD

def determine_assessment_state(
    primary_prediction: Dict[str, Any],
    probabilities: Dict[str, float],
    groq_analysis: Dict[str, Any]
) -> Tuple[str, str]:
    """
    Determines 3-state assessment classification:
    - 'condition'
    - 'normal_appearing'
    - 'uncertain'
    
    Rule: Low model confidence (<45%) does NOT automatically mean normal.
    It defaults to 'uncertain' unless Groq Vision positively confirms normal-appearing skin.
    """
    max_prob = float(primary_prediction.get("confidence", 0.0))
    groq_available = groq_analysis.get("available", False)
    groq_normal = groq_analysis.get("is_normal_appearing")

    # Case A: High model confidence (>= 65%)
    if max_prob >= CONFIDENT_THRESHOLD:
        if groq_available and groq_normal is True:
            # Model is confident, but Groq says skin looks normal
            return "uncertain", "Uncertain — Model & Visual Discrepancy"
        return "condition", "Condition Detected"

    # Case B: Moderate model confidence (45% <= max_prob < 65%)
    elif max_prob >= NORMAL_THRESHOLD:
        if groq_available and groq_normal is True:
            return "normal_appearing", "Normal-Appearing Skin"
        elif groq_available and groq_normal is False:
            return "condition", "Condition Detected"
        else:
            return "condition", "Possible Condition (Moderate Confidence)"

    # Case C: Low model confidence (< 45%) — Classifier is uncertain
    else:
        if groq_available and groq_normal is True:
            # Low classifier signal + Groq positive normal corroboration
            return "normal_appearing", "Normal-Appearing Skin"
        else:
            # Low classifier signal + no normal corroboration -> UNCERTAIN (NOT automatically normal)
            return "uncertain", "Uncertain Assessment — Ambiguous Features"
