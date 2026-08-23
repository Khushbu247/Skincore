import os
import json
import re
import urllib.request
import urllib.error
from typing import List, Dict, Optional, Tuple
from pathlib import Path

# Custom zero-dependency .env loader
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
                        os.environ[k.strip()] = v.strip().strip("'").strip('"')
        except Exception as e:
            print(f"Warning: Could not read .env file: {e}")

load_backend_env()

GROQ_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions"

SKINCORE_SYSTEM_PROMPT = """You are SkinCore AI, an expert dermatology-aware AI assistant integrated inside the SkinCore mobile application.

STRICT FORMATTING & CONCISENESS RULES:
1. BE CONCISE & PRECISE: Give brief, short, and to-the-point answers (max 3-5 numerical or bullet points).
2. NO UNPLEASING MARKDOWN:
   - NEVER use markdown headers ('###' or '##').
   - NEVER use markdown tables ('| Column |'), blockquotes ('>'), or horizontal lines ('---').
   - NEVER use triple asterisks ('***').
3. FORMATTING: Use clean numbered points (1., 2., 3.) or simple bullet points (•).
4. ONLY ELABORATE IF REQUESTED: Provide long or detailed explanations ONLY if the user explicitly asks to 'elaborate', 'give a detailed answer', 'explain in depth', or 'give a detailed guide'.

EXAMPLE ROUTINE ANSWER:
Morning Routine:
1. Gentle Cleanser
2. Vitamin C or Niacinamide Serum
3. Oil-free Moisturizer & Broad Spectrum SPF 30+

Night Routine:
1. Gentle Cleanser
2. Active Treatment (BHA / Retinoid 2-3x weekly)
3. Hydrating Night Cream

Quick Suggestion: Introduce actives gradually and never skip daily sunscreen.
"""

def clean_response(text: str) -> str:
    """Clean up raw markdown artifacts (headers, tables, horizontal rules) to keep responses pleasing to read."""
    if not text:
        return ""
    
    # Remove markdown headers like ### or ##
    text = re.sub(r'^#{1,6}\s*', '', text, flags=re.MULTILINE)
    # Remove horizontal rules ---
    text = re.sub(r'^\s*[-*_]{3,}\s*$', '', text, flags=re.MULTILINE)
    # Remove blockquote symbols >
    text = re.sub(r'^\s*>\s*', '', text, flags=re.MULTILINE)
    # Remove table separators like |---|---|
    text = re.sub(r'\|?\s*:?-+:?\s*\|', '', text)
    # Convert table rows | col1 | col2 | to clean bullet points
    lines = text.split('\n')
    cleaned_lines = []
    for line in lines:
        if '|' in line:
            parts = [p.strip() for p in line.split('|') if p.strip()]
            if parts:
                cleaned_lines.append('• ' + ' — '.join(parts))
        else:
            cleaned_lines.append(line)
    
    result = '\n'.join(cleaned_lines)
    # Collapse 3+ consecutive newlines into 2
    result = re.sub(r'\n{3,}', '\n\n', result).strip()
    return result


def generate_fallback_reply(user_message: str) -> str:
    """Generate concise, topic-specific fallback reply when API is offline."""
    msg = user_message.lower()

    # Cysts & Bumps (benign vs harmful)
    if "cyst" in msg or "lump" in msg or "bump" in msg or "benign" in msg or "harmful" in msg:
        return (
            "Benign vs. Harmful Cysts & Bumps:\n\n"
            "1. Benign Cysts (Epidermoid/Sebaceous):\n"
            "• Soft or rubbery, smooth bump that moves easily under the skin.\n"
            "• Slow-growing and usually painless.\n\n"
            "2. Harmful or Malignant Lesions:\n"
            "• Hard, firm lump anchored to deeper tissue.\n"
            "• Rapid growth, irregular borders, bleeding, or multi-colored appearance.\n\n"
            "Suggestion: Use SkinCore AI Scan to evaluate suspicious bumps and consult a dermatologist for any rapidly changing lesion."
        )

    # Acne & Breakouts
    if "acne" in msg or "pimple" in msg or "breakout" in msg:
        return (
            "Daily Acne Routine:\n\n"
            "Morning Routine:\n"
            "1. Gentle Cleanser\n"
            "2. Salicylic Acid (BHA 1-2%) or Niacinamide\n"
            "3. Oil-free Moisturizer & SPF 30+\n\n"
            "Night Routine:\n"
            "1. Gentle Cleanser\n"
            "2. Benzoyl Peroxide spot treatment or Retinoid (2-3x weekly)\n"
            "3. Hydrating Night Cream\n\n"
            "Suggestion: Keep skin hydrated and avoid picking at pimples."
        )

    # Dark Spots & Hyperpigmentation
    if "pigment" in msg or "dark spot" in msg or "melasma" in msg:
        return (
            "Hyperpigmentation Care:\n\n"
            "1. Vitamin C Serum: Apply in the morning to brighten skin.\n"
            "2. Niacinamide or Azelaic Acid: Apply at night to fade dark spots.\n"
            "3. Broad-Spectrum SPF 30+: Apply daily to prevent spots from darkening.\n\n"
            "Suggestion: Results take 4-8 weeks of consistent SPF and active treatment."
        )

    # Eczema & Sensitive Skin
    if "eczema" in msg or "rash" in msg or "redness" in msg or "itch" in msg:
        return (
            "Eczema & Redness Care:\n\n"
            "1. Barrier Repair Cream: Look for Ceramides and Hyaluronic Acid.\n"
            "2. Avoid Irritants: Skip fragrances, alcohols, and harsh scrubs.\n"
            "3. Soothing Ingredients: Use Colloidal Oatmeal and Centella (Cica).\n\n"
            "Suggestion: Apply moisturizer immediately after washing while skin is damp."
        )

    # Skin Scan & Score Tips
    if "scan" in msg or "photo" in msg or "score" in msg or "camera" in msg:
        return (
            "Scan Accuracy Tips:\n\n"
            "1. Lighting: Use bright, natural daylight near a window.\n"
            "2. Distance: Hold camera 4-6 inches away with sharp focus.\n"
            "3. Prep: Ensure skin is clean without makeup or heavy cream.\n\n"
            "Suggestion: Take scans at the same time daily for accurate score tracking."
        )

    # Sunscreen & SPF
    if "spf" in msg or "sunscreen" in msg or "sun" in msg:
        return (
            "SPF Guidance:\n\n"
            "1. Rating: Use broad-spectrum SPF 30+ daily.\n"
            "2. Amount: Apply 2 finger-lengths for face and neck.\n"
            "3. Reapplication: Reapply every 2 hours outdoors.\n\n"
            "Suggestion: Sunscreen is essential even on cloudy days."
        )

    # General Short Fallback
    return (
        "SkinCore Skincare Tips:\n\n"
        "1. Cleanse: Wash gently twice daily.\n"
        "2. Treat: Apply targeted serums (BHA, Vitamin C, Retinol).\n"
        "3. Protect: Wear SPF 30+ daily.\n\n"
        "Ask me specific questions about acne, cysts, rashes, dark spots, or daily routines!"
    )


def call_groq_api(messages: List[Dict[str, str]], model_name: str) -> Optional[str]:
    """Helper to send HTTP request to Groq API using urllib."""
    load_backend_env()
    api_key = os.getenv("GROQ_API_KEY", "").strip()
    if not api_key:
        return None

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "User-Agent": "SkinCore-Backend/1.0"
    }

    payload = {
        "model": model_name,
        "messages": messages,
        "temperature": 0.5,
        "max_tokens": 512
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
                        return clean_response(content)
    except urllib.error.HTTPError as e:
        print(f"Groq API HTTPError ({model_name}): {e.code}")
    except Exception as e:
        print(f"Groq API Error ({model_name}): {e}")

    return None


def get_chatbot_response(user_message: str, history: Optional[List[Dict[str, str]]] = None) -> Tuple[str, str]:
    """
    Generate chatbot response using Groq API with fallback model & offline fallback logic.
    Returns tuple of (reply_text, model_used).
    """
    load_backend_env()
    api_key = os.getenv("GROQ_API_KEY", "").strip()
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

    formatted_messages = [{"role": "system", "content": SKINCORE_SYSTEM_PROMPT}]

    if history:
        for msg in history:
            role = msg.get("role", "user")
            content = msg.get("content", "")
            if role in ["user", "assistant", "system"] and content:
                formatted_messages.append({"role": role, "content": content})

    formatted_messages.append({"role": "user", "content": user_message})

    if api_key:
        for model in unique_models:
            reply = call_groq_api(formatted_messages, model)
            if reply:
                return reply, model

    # Fallback to local intelligent assistant response
    return clean_response(generate_fallback_reply(user_message)), "skincore-local-fallback"
