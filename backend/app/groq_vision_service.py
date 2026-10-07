import os
import json
import re
import base64
import urllib.request
import urllib.error
from typing import Dict, Any, Optional
from pathlib import Path
from backend.app.config import GROQ_API_KEY, GROQ_VISION_MODEL

GROQ_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions"

SYSTEM_PROMPT = """You are a specialized dermatological visual analysis assistant for the SkinCore system.
Analyze the provided skin image and return ONLY a single valid JSON object adhering strictly to the schema.

RULES:
1. Do NOT generate any numeric medical probabilities, confidence scores, or percentages (e.g., do NOT output '85% confidence').
2. Assess whether the skin appears visually normal and healthy ('is_normal_appearing': true/false).
3. Identify estimated skin type ('oily', 'dry', 'combination', 'normal', 'sensitive', or 'unknown').
4. Describe visible visual features (texture, redness, lesions, pigmentation, oiliness) using objective visual language.
5. Breakdown observations by visible region (e.g. forehead, cheek, chin, nose, or lesion area). Do not invent non-visible body parts.
6. Flag red flags or high-risk features if visible ('red_flags_present': true/false).
7. Never state a definitive medical diagnosis. Use hedged terminology ("features suggestive of", "visual appearance shows").

JSON SCHEMA TO RETURN:
{
  "is_normal_appearing": boolean,
  "skin_type": string,
  "visual_description": string,
  "region_observations": [
    {
      "region": string,
      "observation": string,
      "severity": string
    }
  ],
  "additional_findings": [string],
  "red_flags_present": boolean
}
"""

VISION_MODELS_TO_TRY = [
    GROQ_VISION_MODEL,
    "qwen/qwen3.8-27b"
]


def encode_image_to_base64(image_path: str) -> str:
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode("utf-8")

def parse_json_from_text(text: str) -> Optional[Dict[str, Any]]:
    text = text.strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        match = re.search(r"\{.*\}", text, re.DOTALL)
        if match:
            try:
                return json.loads(match.group(0))
            except json.JSONDecodeError:
                pass
    return None

def normalize_region_observations(raw_obs: Any) -> list:
    """Ensures region_observations is always a list of dicts {region, observation, severity}."""
    if isinstance(raw_obs, list):
        normalized = []
        for item in raw_obs:
            if isinstance(item, dict):
                normalized.append({
                    "region": str(item.get("region", "general")),
                    "observation": str(item.get("observation", "")),
                    "severity": str(item.get("severity", "moderate"))
                })
            elif isinstance(item, str):
                normalized.append({
                    "region": "general",
                    "observation": item,
                    "severity": "moderate"
                })
        return normalized
    elif isinstance(raw_obs, dict):
        normalized = []
        for reg_key, reg_val in raw_obs.items():
            if isinstance(reg_val, str):
                normalized.append({
                    "region": str(reg_key),
                    "observation": reg_val,
                    "severity": "moderate"
                })
            elif isinstance(reg_val, dict):
                normalized.append({
                    "region": str(reg_key),
                    "observation": str(reg_val.get("observation", "")),
                    "severity": str(reg_val.get("severity", "moderate"))
                })
        return normalized
    return []

def analyze_skin_image_groq(image_path: str, timeout_seconds: int = 15) -> Dict[str, Any]:
    api_key = os.environ.get("GROQ_API_KEY", GROQ_API_KEY)
    if not api_key:
        return {
            "available": False,
            "error": "GROQ_API_KEY missing",
            "is_normal_appearing": None,
            "skin_type": "unknown",
            "visual_description": "",
            "region_observations": [],
            "additional_findings": [],
            "red_flags_present": False,
            "model_used": None
        }

    try:
        base64_image = encode_image_to_base64(image_path)
    except Exception as e:
        return {
            "available": False,
            "error": f"Image encoding failed: {str(e)}",
            "is_normal_appearing": None,
            "skin_type": "unknown",
            "visual_description": "",
            "region_observations": [],
            "additional_findings": [],
            "red_flags_present": False,
            "model_used": None
        }

    ext = Path(image_path).suffix.lower()
    mime_type = "image/jpeg"
    if ext in [".png"]:
        mime_type = "image/png"
    elif ext in [".webp"]:
        mime_type = "image/webp"

    image_url_str = f"data:{mime_type};base64,{base64_image}"

    models_to_attempt = []
    for m in VISION_MODELS_TO_TRY:
        if m and m not in models_to_attempt:
            models_to_attempt.append(m)

    last_error = None
    for model_name in models_to_attempt:
        payload = {
            "model": model_name,
            "messages": [
                {
                    "role": "system",
                    "content": SYSTEM_PROMPT
                },
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": "Analyze this skin image according to the JSON schema. Focus on visual description, skin type, and region observations."
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": image_url_str
                            }
                        }
                    ]
                }
            ],
            "temperature": 0.2,
            "max_tokens": 800,
            "response_format": {"type": "json_object"}
        }

        req = urllib.request.Request(
            GROQ_ENDPOINT,
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {api_key}",
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) SkinCore-Vision-Service/1.0"
            },
            method="POST"
        )

        try:
            with urllib.request.urlopen(req, timeout=timeout_seconds) as response:
                if response.status == 200:
                    resp_body = response.read().decode("utf-8")
                    resp_json = json.loads(resp_body)
                    choices = resp_json.get("choices", [])
                    if choices:
                        content_text = choices[0].get("message", {}).get("content", "")
                        parsed_data = parse_json_from_text(content_text)
                        if parsed_data and isinstance(parsed_data, dict):
                            raw_regions = parsed_data.get("region_observations", [])
                            norm_regions = normalize_region_observations(raw_regions)
                            return {
                                "available": True,
                                "error": None,
                                "is_normal_appearing": parsed_data.get("is_normal_appearing"),
                                "skin_type": str(parsed_data.get("skin_type", "unknown")),
                                "visual_description": str(parsed_data.get("visual_description", "")),
                                "region_observations": norm_regions,
                                "additional_findings": list(parsed_data.get("additional_findings", [])),
                                "red_flags_present": bool(parsed_data.get("red_flags_present", False)),
                                "model_used": model_name
                            }

        except urllib.error.HTTPError as he:
            err_msg = f"HTTP {he.code}: {he.reason}"
            try:
                err_body = he.read().decode("utf-8")
                err_msg += f" - {err_body}"
            except Exception:
                pass
            last_error = err_msg
            continue
        except Exception as ex:
            last_error = str(ex)
            continue

    return {
        "available": False,
        "error": last_error or "All vision models failed or timed out",
        "is_normal_appearing": None,
        "skin_type": "unknown",
        "visual_description": "",
        "region_observations": [],
        "additional_findings": [],
        "red_flags_present": False,
        "model_used": None
    }
