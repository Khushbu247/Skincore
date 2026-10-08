from typing import List, Dict, Any
from backend.app.schemas import RecommendedProductItem, CategoryIngredientGuidance
from backend.app.product_discovery_service import NormalizedProduct

def get_price_band(price_inr: float) -> str:
    """Non-overlapping price band mapping."""
    if price_inr <= 500.0:
        return "budget"
    elif 501.0 <= price_inr <= 1000.0:
        return "mid_range"
    else:
        return "premium"

def compute_suitability_score(
    product: NormalizedProduct,
    recommended_actives: List[str],
    avoided_ingredients: List[str],
    user_skin_type: str,
    user_concerns: List[str]
) -> tuple[float, str]:
    """
    Programmatic Suitability Score Formula (0 to 100 bounded compatibility score).
    Represents catalog/product compatibility with AI-recommended ingredients and user profile.
    NOT a medical probability.
    """
    base_score = 50.0

    # 1. Ingredient Match Points (max 25 pts)
    matched_ingredients = []
    if recommended_actives and product.key_ingredients:
        for rec in recommended_actives:
            rec_clean = rec.lower().strip()
            for prod_ing in product.key_ingredients:
                prod_clean = prod_ing.lower().strip()
                if rec_clean in prod_clean or prod_clean in rec_clean:
                    matched_ingredients.append(rec)
                    break
        
        ratio = len(matched_ingredients) / max(1, len(recommended_actives))
        ingredient_pts = 25.0 * ratio
    else:
        ingredient_pts = 12.5  # Neutral default for partial metadata

    # 2. Skin Type Match Points (max 15 pts)
    skin_type_pts = 0.0
    if product.suitable_skin_types:
        types_lower = [t.lower().strip() for t in product.suitable_skin_types]
        user_type_clean = user_skin_type.lower().strip()
        if user_type_clean in types_lower or "all" in types_lower or "normal" in types_lower:
            skin_type_pts = 15.0
        else:
            skin_type_pts = 5.0
    else:
        skin_type_pts = 7.5

    # 3. Concern Match Points (max 10 pts)
    concern_pts = 0.0
    if user_concerns and product.target_concerns:
        user_concerns_lower = [c.lower().strip() for c in user_concerns]
        target_lower = [t.lower().strip() for t in product.target_concerns]
        match_found = any(uc in target for uc in user_concerns_lower for target in target_lower)
        if match_found:
            concern_pts = 10.0
        else:
            concern_pts = 5.0
    else:
        concern_pts = 5.0

    # 4. Conflict Penalties (penalty 40 pts)
    conflict_penalty = 0.0
    if avoided_ingredients and product.key_ingredients:
        for avoid in avoided_ingredients:
            avoid_clean = avoid.lower().strip()
            for prod_ing in product.key_ingredients:
                prod_clean = prod_ing.lower().strip()
                if avoid_clean in prod_clean or prod_clean in avoid_clean:
                    conflict_penalty = 40.0
                    break

    raw_score = base_score + ingredient_pts + skin_type_pts + concern_pts - conflict_penalty
    final_score = max(0.0, min(100.0, raw_score))

    # Badge Mapping
    if final_score >= 90.0:
        badge = "Highly Suitable"
    elif final_score >= 70.0:
        badge = "Suitable"
    elif final_score >= 50.0:
        badge = "Potentially Suitable"
    else:
        badge = "Not Recommended"

    return final_score, badge


def rank_and_build_product_items(
    guidance_list: List[CategoryIngredientGuidance],
    discovered_products_by_category: Dict[str, List[NormalizedProduct]],
    user_skin_type: str,
    user_concerns: List[str]
) -> List[RecommendedProductItem]:
    """
    Ranks products deterministically for each category based on suitability score,
    and returns a sorted list of RecommendedProductItems.
    """
    final_items: List[RecommendedProductItem] = []

    # Map guidance per category
    guidance_map = {g.category.lower(): g for g in guidance_list}

    for cat_name, raw_products in discovered_products_by_category.items():
        cat_lower = cat_name.lower()
        guidance = guidance_map.get(cat_lower)

        rec_actives = guidance.recommended_actives if guidance else []
        avoid_ing = guidance.avoided_ingredients if guidance else []
        why_works = guidance.rationale if guidance else f"Specially formulated for {user_skin_type} skin."
        usage_time = guidance.usage_time if guidance else "AM/PM"
        how_to_use = guidance.how_to_use if guidance else "Apply evenly to clean skin."
        conflicts = guidance.safety_warnings if guidance else []

        ranked_category_items = []
        for prod in raw_products:
            score, badge = compute_suitability_score(
                product=prod,
                recommended_actives=rec_actives,
                avoided_ingredients=avoid_ing,
                user_skin_type=user_skin_type,
                user_concerns=user_concerns
            )

            # Filter out products below 50 compatibility score
            if score < 50.0 and len(raw_products) > 1:
                continue

            price_band = get_price_band(prod.price_inr)

            item = RecommendedProductItem(
                product_id=prod.product_id,
                name=prod.name,
                brand=prod.brand,
                category=prod.category,
                description=prod.description,
                price_inr=prod.price_inr,
                price_band=price_band,
                image_url=prod.image_url,
                buy_url=prod.buy_url,
                key_ingredients=prod.key_ingredients or rec_actives,
                suitability_score=round(score, 1),
                suitability_badge=badge,
                usage_time=usage_time,
                why_it_works=why_works,
                how_to_use=how_to_use,
                warnings_or_conflicts=conflicts,
                source=prod.source
            )
            ranked_category_items.append((score, item))

        # Sort products descending by suitability score
        ranked_category_items.sort(key=lambda x: x[0], reverse=True)
        for _, item in ranked_category_items:
            final_items.append(item)

    return final_items
