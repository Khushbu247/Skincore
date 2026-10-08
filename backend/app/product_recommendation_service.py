import os
import json
import re
import hashlib
import urllib.request
import urllib.error
from typing import List, Dict, Any, Optional, Tuple
from pathlib import Path

from backend.app.schemas import (
    RecommendationRequest,
    ProductRecommendationResponse,
    CategoryIngredientGuidance,
    RecommendedProductItem
)
from backend.app.product_discovery_service import product_discovery_service
from backend.app.product_ranker import rank_and_build_product_items

def load_backend_env():
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
        except Exception:
            pass

load_backend_env()

GROQ_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions"

# Isolated Groq Recommendation System Prompt
GROQ_RECOMMENDATION_SYSTEM_PROMPT = """You are SkinCore AI, an ingredient-focused cosmetic skincare recommendation assistant.
Your task is to analyze the user's questionnaire report and latest skin analysis report to provide ingredient-focused skincare recommendations.

CRITICAL CONSTRAINTS:
1. Do NOT diagnose medical conditions, prescribe medication, or claim to cure diseases.
2. Use cosmetic language only ("helps support", "formulated to target", "gentle skincare guidance").
3. Recommend key active ingredients and routine guidance for appropriate categories (Cleanser, Serum, Moisturizer, Sunscreen, Exfoliant, Eye Care).
4. Identify ingredients to avoid or potential conflicts based on user reported symptoms, triggers, and skin sensitivity.
5. Provide usage timing (AM, PM, or AM/PM) and concise step-by-step how-to-use instructions for each category.
6. DO NOT INVENT BRANDS, SPECIFIC PRODUCT NAMES, PRICES, OR STORE URLS. Output ONLY ingredient guidance, category rationale, and safety notes.
7. Respond STRICTLY in valid JSON matching the exact schema requested below.

JSON SCHEMA:
{
  "skin_type_summary": "<String, e.g. Combination, Oily, Sensitive>",
  "summary_ai_insight": "<2-3 sentence AI personalization rationale>",
  "serious_condition_detected": <boolean, true if high risk or serious condition signal detected>,
  "medical_warning_banner": "<String warning or null>",
  "category_guidance": [
    {
      "category": "<Cleanser | Serum | Moisturizer | Sunscreen | Exfoliant | Eye Care>",
      "recommended_actives": ["<Ingredient 1>", "<Ingredient 2>"],
      "avoided_ingredients": ["<Avoided 1>", "<Avoided 2>"],
      "rationale": "<Why it works for the user's skin profile>",
      "usage_time": "<AM | PM | AM/PM>",
      "how_to_use": "<Step-by-step guidance>",
      "safety_warnings": ["<Warning or conflict note if any>"]
    }
  ]
}
"""

# In-memory recommendation cache storage (cache_key -> payload)
_RECOMMENDATION_CACHE: Dict[str, ProductRecommendationResponse] = {}

def calculate_cache_key(q_report_id: Optional[str], s_report_id: Optional[str]) -> str:
    raw_str = f"q:{q_report_id or 'none'}|s:{s_report_id or 'none'}"
    return hashlib.sha256(raw_str.encode("utf-8")).hexdigest()[:24]

def call_groq_recommendation_api(messages: List[Dict[str, str]]) -> Optional[str]:
    load_backend_env()
    api_key = os.getenv("GROQ_API_KEY", "").strip()
    if not api_key:
        return None

    primary_model = os.getenv("GROQ_MODEL", "openai/gpt-oss-120b").strip()
    fallback_model = os.getenv("FALLBACK_MODEL", "qwen/qwen3.6-27b").strip()

    candidate_models = [
        primary_model,
        fallback_model,
        "openai/gpt-oss-20b",
        "groq/compound-mini"
    ]

    unique_models = []
    for m in candidate_models:
        if m and m not in unique_models:
            unique_models.append(m)

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "User-Agent": "SkinCore-RecommendationEngine/1.0"
    }

    for model_name in unique_models:
        payload = {
            "model": model_name,
            "messages": messages,
            "temperature": 0.3,
            "max_tokens": 1200
        }

        try:
            req = urllib.request.Request(
                GROQ_ENDPOINT,
                data=json.dumps(payload).encode("utf-8"),
                headers=headers,
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=15) as response:
                if response.status == 200:
                    res_body = json.loads(response.read().decode("utf-8"))
                    choices = res_body.get("choices", [])
                    if choices:
                        content = choices[0].get("message", {}).get("content", "").strip()
                        if content:
                            # Extract JSON block if surrounded by markdown fences
                            if "```json" in content:
                                content = content.split("```json")[1].split("```")[0].strip()
                            elif "```" in content:
                                content = content.split("```")[1].split("```")[0].strip()
                            return content
        except Exception as e:
            print(f"Groq Recommendation API Error ({model_name}): {e}")

    return None


def generate_heuristic_guidance(
    skin_type: str,
    main_concern: str,
    prediction: str,
    is_serious: bool
) -> Dict[str, Any]:
    """Fallback structured ingredient guidance when Groq API is unavailable."""
    st_clean = skin_type.lower()
    concern_clean = main_concern.lower()

    # Default categories & ingredients
    categories = []

    # 1. Cleanser
    if "oily" in st_clean or "acne" in concern_clean or "acne" in prediction.lower():
        cleanser_actives = ["Salicylic Acid (BHA 1-2%)", "Niacinamide", "Glycerin"]
        cleanser_rationale = "Helps unclog pores and regulate excess sebum while maintaining natural moisture balance."
    elif "dry" in st_clean or "eczema" in prediction.lower():
        cleanser_actives = ["Colloidal Oatmeal", "Ceramides", "Hyaluronic Acid"]
        cleanser_rationale = "Gentle, non-foaming hydrating cleanser to reinforce the disrupted epidermal skin barrier."
    else:
        cleanser_actives = ["Centella Asiatica (Cica)", "Glycerin", "Panthenol"]
        cleanser_rationale = "Gentle daily cleanser suitable for maintaining balanced, comfortable skin barrier."

    categories.append({
        "category": "Cleanser",
        "recommended_actives": cleanser_actives,
        "avoided_ingredients": ["Harsh Sulfates (SLS/SLES)", "Alcohol Denat", "Synthetic Fragrance"],
        "rationale": cleanser_rationale,
        "usage_time": "AM/PM",
        "how_to_use": "Massage 1-2 pumps onto damp face for 60 seconds, then rinse with lukewarm water.",
        "safety_warnings": ["Avoid direct contact with eye area."]
    })

    # 2. Serum / Treatment
    if "pigment" in concern_clean or "pigmentation" in prediction.lower():
        serum_actives = ["Niacinamide (5%)", "Alpha Arbutin (2%)", "Vitamin C (L-Ascorbic Acid)"]
        serum_rationale = "Targeted active complex to inhibit dark spot development and promote even skin tone."
        serum_timing = "AM"
    elif "acne" in concern_clean or "acne" in prediction.lower():
        serum_actives = ["Niacinamide", "Azelaic Acid (10%)", "Zinc PCA"]
        serum_rationale = "Anti-inflammatory active complex to calm active breakouts and diminish redness."
        serum_timing = "PM"
    else:
        serum_actives = ["Hyaluronic Acid", "Panthenol (Vitamin B5)", "Peptides"]
        serum_rationale = "Deep hydrating serum complex to lock in moisture and promote skin elasticity."
        serum_timing = "AM/PM"

    categories.append({
        "category": "Serum",
        "recommended_actives": serum_actives,
        "avoided_ingredients": ["High-concentration Hydroquinone without medical supervision"],
        "rationale": serum_rationale,
        "usage_time": serum_timing,
        "how_to_use": "Apply 3-4 drops onto clean skin before applying heavier moisturizer.",
        "safety_warnings": ["Perform patch test behind ear before full facial application."]
    })

    # 3. Moisturizer
    if "oily" in st_clean or "combination" in st_clean:
        moist_actives = ["Hyaluronic Acid", "Green Tea Extract", "Aloe Vera"]
        moist_rationale = "Lightweight gel-cream moisturizer providing non-comedogenic hydration without clogging pores."
    else:
        moist_actives = ["Ceramides NP/AP/EOP", "Squalane", "Shea Butter"]
        moist_rationale = "Rich barrier-repair moisturizer to lock in essential skin lipids and prevent transepidermal water loss."

    categories.append({
        "category": "Moisturizer",
        "recommended_actives": moist_actives,
        "avoided_ingredients": ["Heavy mineral oils if acne-prone"],
        "rationale": moist_rationale,
        "usage_time": "AM/PM",
        "how_to_use": "Smooth a nickel-sized amount over face and neck morning and evening.",
        "safety_warnings": []
    })

    # 4. Sunscreen
    categories.append({
        "category": "Sunscreen",
        "recommended_actives": ["Zinc Oxide", "Titanium Dioxide", "Tocopherol (Vitamin E)"],
        "avoided_ingredients": ["Oxybenzone (if sensitive)"],
        "rationale": "Broad-spectrum mineral SPF 30+ protection to guard against UV-induced damage and darkening of spots.",
        "usage_time": "AM",
        "how_to_use": "Apply 2 finger-lengths as the final step of your morning routine 15 minutes before sun exposure.",
        "safety_warnings": ["Reapply every 2 hours when outdoors."]
    })

    # 5. Exfoliant
    categories.append({
        "category": "Exfoliant",
        "recommended_actives": ["Salicylic Acid (BHA 1%)", "Lactic Acid (AHA 5%)"],
        "avoided_ingredients": ["Harsh walnut scrubs", "Over-exfoliating acids"],
        "rationale": "Gentle chemical exfoliator to remove dead skin cells and prevent clogged pores.",
        "usage_time": "PM",
        "how_to_use": "Use 1-2 times weekly at night on clean dry skin. Follow with moisturizer.",
        "safety_warnings": ["Do not use on broken or inflamed skin."]
    })

    # 6. Eye Care
    categories.append({
        "category": "Eye Care",
        "recommended_actives": ["Caffeine", "Hyaluronic Acid", "Niacinamide"],
        "avoided_ingredients": ["Essential oils"],
        "rationale": "Soothes delicate periocular skin, reducing puffiness and fine hydration lines.",
        "usage_time": "AM/PM",
        "how_to_use": "Gently tap a pea-sized amount around orbital bone using ring finger.",
        "safety_warnings": ["Do not get product directly into eyes."]
    })

    banner = None
    if is_serious:
        banner = "SkinCore AI detected high-risk skin signals. Cosmetic recommendations support skin health but do NOT replace evaluation by a board-certified dermatologist."

    return {
        "skin_type_summary": skin_type,
        "summary_ai_insight": f"Personalized active ingredient plan designed for {skin_type} skin targeting {main_concern}.",
        "serious_condition_detected": is_serious,
        "medical_warning_banner": banner,
        "category_guidance": categories
    }


def generate_recommendations(req: RecommendationRequest) -> ProductRecommendationResponse:
    q_id = req.questionnaire_report_id
    s_id = req.latest_skin_analysis_report_id

    # 1. Prerequisite verification
    missing = []
    if not q_id and not req.questionnaire_answers:
        missing.append("questionnaire")
    if not s_id and not req.latest_skin_analysis:
        missing.append("skin_analysis")

    if missing:
        return ProductRecommendationResponse(
            status="missing_prerequisites",
            cache_key="",
            missing_prerequisites=missing,
            error_message="Questionnaire and Skin Analysis reports are required before generating personalized recommendations."
        )

    # 2. Derive Cache Key
    cache_key = calculate_cache_key(q_id, s_id)

    # Check cache unless force_refresh is requested
    if not req.force_refresh and cache_key in _RECOMMENDATION_CACHE:
        cached_resp = _RECOMMENDATION_CACHE[cache_key]
        cached_resp.is_cached = True
        return cached_resp

    # 3. Extract Report Data
    q_answers = req.questionnaire_answers or {}
    s_data = req.latest_skin_analysis or {}

    skin_type = q_answers.get("skin_type") or s_data.get("skinType") or "Combination"
    main_concern = q_answers.get("main_concern") or s_data.get("prediction") or "General Skin Care"
    if isinstance(main_concern, list):
        main_concern = ", ".join(main_concern)

    prediction = str(s_data.get("prediction", "acne"))
    risk_level = str(s_data.get("riskLevel", "Low Risk"))

    is_serious = (
        "serious" in prediction.lower() or
        "high risk" in risk_level.lower() or
        bool(s_data.get("needsProfessionalReview", False))
    )

    # 4. Layer 1 Groq AI Reasoning
    user_prompt = f"""
USER REPORT SUMMARY:
- Skin Type: {skin_type}
- Main Concern(s): {main_concern}
- Reported Symptoms: {q_answers.get('symptoms', 'Not specified')}
- Reported Triggers: {q_answers.get('triggers', 'Not specified')}
- Current Routine Products: {q_answers.get('products', 'Not specified')}
- User Help Request: {q_answers.get('help_request', 'General skincare guidance')}

AI SKIN SCAN OBSERVATIONS:
- Primary Classification: {prediction}
- Risk Level: {risk_level}
- Key Observations: {s_data.get('keyObservations', [])}
- Serious Condition Alert: {is_serious}

Provide structured ingredient-focused cosmetic guidance matching the schema.
"""

    messages = [
        {"role": "system", "content": GROQ_RECOMMENDATION_SYSTEM_PROMPT},
        {"role": "user", "content": user_prompt}
    ]

    groq_raw = call_groq_recommendation_api(messages)
    ai_guidance_dict = None

    if groq_raw:
        try:
            ai_guidance_dict = json.loads(groq_raw)
        except Exception as e:
            print(f"Error parsing Groq Recommendation JSON: {e}")

    if not ai_guidance_dict or "category_guidance" not in ai_guidance_dict:
        ai_guidance_dict = generate_heuristic_guidance(
            skin_type=skin_type,
            main_concern=main_concern,
            prediction=prediction,
            is_serious=is_serious
        )

    # Parse Category Guidance
    guidance_list: List[CategoryIngredientGuidance] = []
    discovered_products_by_category: Dict[str, List[Any]] = {}

    concerns_list = [c.strip() for c in main_concern.split(",") if c.strip()]

    for cat_data in ai_guidance_dict.get("category_guidance", []):
        cat_obj = CategoryIngredientGuidance(
            category=cat_data.get("category", "General"),
            recommended_actives=cat_data.get("recommended_actives", []),
            avoided_ingredients=cat_data.get("avoided_ingredients", []),
            rationale=cat_data.get("rationale", ""),
            usage_time=cat_data.get("usage_time", "AM/PM"),
            how_to_use=cat_data.get("how_to_use", ""),
            safety_warnings=cat_data.get("safety_warnings", [])
        )
        guidance_list.append(cat_obj)

        # 5. Dynamic Product Discovery for each category
        prods = product_discovery_service.discover_products_for_guidance(
            category=cat_obj.category,
            recommended_ingredients=cat_obj.recommended_actives,
            skin_type=skin_type,
            concerns=concerns_list
        )
        discovered_products_by_category[cat_obj.category] = prods

    # 6. Layer 2 Deterministic Product Matching & Ranking
    final_products: List[RecommendedProductItem] = rank_and_build_product_items(
        guidance_list=guidance_list,
        discovered_products_by_category=discovered_products_by_category,
        user_skin_type=skin_type,
        user_concerns=concerns_list
    )

    med_banner = ai_guidance_dict.get("medical_warning_banner")
    if is_serious and not med_banner:
        med_banner = "SkinCore AI detected high-risk skin signals. Cosmetic recommendations support skin health but do NOT replace evaluation by a board-certified dermatologist."

    response = ProductRecommendationResponse(
        status="success",
        cache_key=cache_key,
        is_cached=False,
        skin_type_summary=ai_guidance_dict.get("skin_type_summary", skin_type),
        summary_ai_insight=ai_guidance_dict.get("summary_ai_insight", f"Personalized plan tailored for {skin_type} skin."),
        serious_condition_detected=is_serious,
        medical_warning_banner=med_banner,
        category_guidance=guidance_list,
        products=final_products
    )

    # Save in recommendation cache
    _RECOMMENDATION_CACHE[cache_key] = response

    return response
