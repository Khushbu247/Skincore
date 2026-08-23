import os
import json
import urllib.request
import urllib.error

with open("backend/.env", "r") as f:
    for line in f:
        line = line.strip()
        if line and "=" in line and not line.startswith("#"):
            k, v = line.split("=", 1)
            os.environ[k.strip()] = v.strip().strip("'").strip('"')

key = os.environ.get("GROQ_API_KEY")

test_models = [
    "llama-3.3-70b-versatile",
    "llama-3.3-70b-instruct",
    "llama-3.1-8b-instant",
    "llama-3.1-70b-versatile",
    "groq/compound",
    "groq/compound-mini",
    "openai/gpt-oss-120b",
    "openai/gpt-oss-20b",
    "qwen/qwen3.6-27b",
    "llama3-groq-70b-8192-tool-use-preview",
    "llama3-groq-8b-8192-tool-use-preview",
    "deepseek-r1-distill-llama-70b",
    "gemma2-9b-it"
]

headers = {
    "Authorization": f"Bearer {key}",
    "Content-Type": "application/json",
    "User-Agent": "SkinCore/1.0"
}

for m in test_models:
    payload = {
        "model": m,
        "messages": [{"role": "user", "content": "How to distinguish between benign and harmful cysts?"}]
    }
    try:
        req = urllib.request.Request(
            "https://api.groq.com/openai/v1/chat/completions",
            data=json.dumps(payload).encode("utf-8"),
            headers=headers,
            method="POST"
        )
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            content = data["choices"][0]["message"]["content"]
            print(f"\n================ SUCCESS FOR MODEL '{m}' ================")
            print(content[:300])
            print("=======================================================\n")
            break
    except urllib.error.HTTPError as e:
        print(f"FAILED '{m}': HTTP {e.code} - {e.read().decode('utf-8')[:120]}")
    except Exception as e:
        print(f"ERROR '{m}': {e}")
